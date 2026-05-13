import datetime
import json
import math
from pydantic import BaseModel
from app.core.models import (
    CrisisEvent,
    ActionSimulation,
    ResourceAllocation,
    Resource,
    RoadClosure,
    DispatchTrack,
    AlertZone,
    EmergencyTicket,
    AlertLogEntry,
)
from app.agents.base import BaseAgent


class Action(BaseModel):
    action_type: str
    before_state: str
    action_description: str
    expected_after_state: str
    response_time_improvement: str
    congestion_impact: str
    resource_cost: str
    side_effects: str


class SimulationResponse(BaseModel):
    actions: list[Action]


SEVERITY_RADIUS_KM = {"Critical": 5.0, "High": 3.5, "Medium": 2.0, "Low": 1.0}
SEVERITY_POP_DENSITY = {"Critical": 12000, "High": 7000, "Medium": 3500, "Low": 1500}
EVENT_TYPE_NEEDS_CLOSURE = {
    "flood",
    "flooding",
    "urban_flooding",
    "road_blockage",
    "accident",
    "infrastructure_failure",
    "fire",
    "earthquake",
    "landslide",
}
SEVERITY_PRIORITY = {
    "Critical": "P1",
    "High": "P2",
    "Medium": "P3",
    "Low": "P4",
}
RESOURCE_ASSIGNEE = {
    "ambulance": "EMS Dispatch",
    "police": "Police Dispatch",
    "rescue_team": "Rescue Command",
    "fire": "Fire Dispatch",
}


class SimulationAgent(BaseAgent):
    def __init__(self):
        super().__init__("SimulationAgent")

    def run(self, db):
        self.traces = []
        events = db.query(CrisisEvent).filter(CrisisEvent.status == "active").all()
        if not events:
            return {"message": "No events"}

        summary = {
            "events_processed": 0,
            "actions_logged": 0,
            "closures_created": 0,
            "dispatches_created": 0,
            "alert_zones_created": 0,
            "tickets_created": 0,
            "log_entries_created": 0,
        }

        for e in events:
            already_dispatched = (
                db.query(DispatchTrack).filter(DispatchTrack.event_id == e.id).count()
            )
            already_zones = (
                db.query(AlertZone).filter(AlertZone.event_id == e.id).count()
            )
            already_closures = (
                db.query(RoadClosure).filter(RoadClosure.event_id == e.id).count()
            )

            priority = SEVERITY_PRIORITY.get(e.severity, "P3")
            self._log(
                db,
                summary,
                event_id=e.id,
                channel="system",
                level=self._severity_level(e.severity),
                title=f"Simulation started for {e.title}",
                message=(
                    f"Planning response actions for {e.event_type} (severity {e.severity}, "
                    f"priority {priority})."
                ),
            )

            actions, plan_status, plan_prompt = self._plan_actions(e)
            for a in actions:
                db.add(
                    ActionSimulation(
                        event_id=e.id,
                        action_type=a["action_type"],
                        before_state=a["before_state"],
                        action_description=a["action_description"],
                        expected_after_state=a["expected_after_state"],
                        response_time_improvement=a["response_time_improvement"],
                        congestion_impact=a["congestion_impact"],
                        resource_cost=a["resource_cost"],
                        side_effects=a["side_effects"],
                    )
                )
                summary["actions_logged"] += 1
                self._log(
                    db,
                    summary,
                    event_id=e.id,
                    channel="plan",
                    level="info",
                    title=f"Plan · {a['action_type']}",
                    message=a["action_description"],
                )
                self._record(
                    db,
                    stage="simulate",
                    summary=f"[{a['action_type']}] {a['action_description']}",
                    reasoning=(
                        f"Before: {a['before_state']} → After: {a['expected_after_state']}. "
                        f"Response time: {a['response_time_improvement']}. "
                        f"Congestion: {a['congestion_impact']}. "
                        f"Cost: {a['resource_cost']}. "
                        f"Side effects: {a['side_effects']}."
                    ),
                    event_id=e.id,
                    status=plan_status,
                    prompt=plan_prompt,
                    decision=a,
                )

            if not already_dispatched:
                summary["dispatches_created"] += self._materialize_dispatches(
                    db, e, summary, priority
                )
            if not already_zones:
                summary["alert_zones_created"] += self._materialize_alert_zone(
                    db, e, summary, priority
                )
            if not already_closures and self._needs_closures(e):
                summary["closures_created"] += self._materialize_closures(
                    db, e, summary, priority
                )

            summary["events_processed"] += 1

        db.commit()
        return summary

    def _plan_actions(self, e):
        prompt = (
            f"Simulate response actions for crisis: {e.title}. "
            f"Type: {e.event_type}. Severity: {e.severity}."
        )
        try:
            res = json.loads(self.llm.generate(prompt, SimulationResponse, temp=0.2))
            return res["actions"], "ok", prompt
        except Exception as ex:
            self.logger.error(f"LLM fail: {ex}")
            return self._fallback_actions(e), "fallback", prompt

    def _fallback_actions(self, e):
        return [
            {
                "action_type": "alert",
                "before_state": "Public unaware",
                "action_description": f"Broadcast advisory for {e.title}",
                "expected_after_state": "Public informed within affected radius",
                "response_time_improvement": "N/A",
                "congestion_impact": "Low",
                "resource_cost": "Low",
                "side_effects": "None",
            },
            {
                "action_type": "dispatch",
                "before_state": "Units staged at base",
                "action_description": "Dispatch nearest available units to scene",
                "expected_after_state": "Units en route",
                "response_time_improvement": "~30%",
                "congestion_impact": "Medium",
                "resource_cost": "Allocated",
                "side_effects": "Reduces fleet availability",
            },
        ]

    def _materialize_dispatches(self, db, e, summary, priority):
        allocations = (
            db.query(ResourceAllocation)
            .filter(ResourceAllocation.event_id == e.id)
            .all()
        )
        count = 0
        for alloc in allocations:
            res = db.query(Resource).filter(Resource.id == alloc.resource_id).first()
            if not res:
                continue
            track = DispatchTrack(
                event_id=e.id,
                resource_id=res.id,
                allocation_id=alloc.id,
                units=alloc.units_allocated,
                from_lat=res.base_lat,
                from_lng=res.base_lng,
                to_lat=e.lat,
                to_lng=e.lng,
                current_lat=res.base_lat,
                current_lng=res.base_lng,
                eta_minutes=alloc.travel_time_minutes,
                progress=0.0,
                status="enroute",
            )
            db.add(track)
            db.flush()
            if res.available_units < res.total_units and res.status == "available":
                res.status = "deployed"
            count += 1

            ticket = EmergencyTicket(
                event_id=e.id,
                ticket_code=self._ticket_code("DSP", e.id, count),
                category="dispatch",
                priority=priority,
                title=f"Dispatch {res.name} ({alloc.units_allocated}u)",
                description=(
                    f"{alloc.units_allocated} × {res.resource_type} from {res.name} "
                    f"en route to {e.title}. ETA {alloc.travel_time_minutes:.1f} min."
                ),
                assignee=RESOURCE_ASSIGNEE.get(res.resource_type, "Ops Command"),
                status="open",
                eta_minutes=alloc.travel_time_minutes,
                resource_id=res.id,
                dispatch_id=track.id,
            )
            db.add(ticket)
            db.flush()
            summary["tickets_created"] += 1
            self._log(
                db,
                summary,
                event_id=e.id,
                channel="dispatch",
                level="warn",
                title=f"Ticket {ticket.ticket_code} · {res.name}",
                message=(
                    f"{alloc.units_allocated} unit(s) dispatched · "
                    f"ETA {alloc.travel_time_minutes:.1f} min · "
                    f"assignee {ticket.assignee}."
                ),
                ticket_id=ticket.id,
            )
        return count

    def _materialize_alert_zone(self, db, e, summary, priority):
        radius = e.affected_radius_km or SEVERITY_RADIUS_KM.get(e.severity, 2.0)
        density = SEVERITY_POP_DENSITY.get(e.severity, 4000)
        broadcast = int(math.pi * radius * radius * density)
        msg = (
            f"[{e.severity.upper()}] {e.event_type.replace('_', ' ').title()}: "
            f"avoid area within {radius:.1f} km of incident. Follow official directions."
        )
        zone = AlertZone(
            event_id=e.id,
            center_lat=e.lat,
            center_lng=e.lng,
            radius_km=radius,
            severity=e.severity,
            message=msg,
            broadcast_count=broadcast,
            status="active",
        )
        db.add(zone)
        db.flush()

        ticket = EmergencyTicket(
            event_id=e.id,
            ticket_code=self._ticket_code("ALR", e.id, 1),
            category="alert",
            priority=priority,
            title=f"Public alert · {radius:.1f} km radius",
            description=(
                f"Broadcast advisory to ~{broadcast:,} residents within {radius:.1f} km "
                f"of incident center."
            ),
            assignee="Public Comms",
            status="open",
            zone_id=zone.id,
        )
        db.add(ticket)
        db.flush()
        summary["tickets_created"] += 1
        self._log(
            db,
            summary,
            event_id=e.id,
            channel="alert",
            level=self._severity_level(e.severity),
            title=f"Alert broadcast · {radius:.1f} km",
            message=f"Reaching ~{broadcast:,} people. {msg}",
            ticket_id=ticket.id,
        )
        return 1

    def _needs_closures(self, e):
        return (e.event_type or "").lower().replace(" ", "_") in EVENT_TYPE_NEEDS_CLOSURE

    def _materialize_closures(self, db, e, summary, priority):
        radius = e.affected_radius_km or SEVERITY_RADIUS_KM.get(e.severity, 2.0)
        offset = max(0.0025, min(0.02, radius / 200.0))
        segments = [
            ("North approach", offset, 0.0, offset * 0.6, offset * 0.7),
            ("East approach", 0.0, offset, -offset * 0.6, offset * 0.7),
            ("South approach", -offset, 0.0, -offset * 0.6, -offset * 0.7),
        ]
        reason = f"Closed due to {e.event_type.replace('_', ' ')}"
        for idx, (label, dlat1, dlng1, dlat2, dlng2) in enumerate(segments, start=1):
            closure = RoadClosure(
                event_id=e.id,
                label=label,
                reason=reason,
                from_lat=e.lat + dlat1,
                from_lng=e.lng + dlng1,
                to_lat=e.lat + dlat2,
                to_lng=e.lng + dlng2,
                status="active",
            )
            db.add(closure)
            db.flush()
            ticket = EmergencyTicket(
                event_id=e.id,
                ticket_code=self._ticket_code("TRF", e.id, idx),
                category="traffic_control",
                priority=priority,
                title=f"Close {label}",
                description=f"{label} closed. {reason}.",
                assignee="Traffic Control",
                status="open",
                closure_id=closure.id,
            )
            db.add(ticket)
            db.flush()
            summary["tickets_created"] += 1
            self._log(
                db,
                summary,
                event_id=e.id,
                channel="closure",
                level="warn",
                title=f"Closure · {label}",
                message=f"{label} closed. {reason}.",
                ticket_id=ticket.id,
            )
        return len(segments)

    def _log(self, db, summary, *, event_id, channel, level, title, message, ticket_id=None):
        db.add(
            AlertLogEntry(
                event_id=event_id,
                channel=channel,
                level=level,
                title=title[:200],
                message=message[:1000],
                ticket_id=ticket_id,
            )
        )
        summary["log_entries_created"] += 1

    def _ticket_code(self, prefix, event_id, idx):
        ts = datetime.datetime.utcnow().strftime("%H%M%S")
        return f"{prefix}-{event_id:04d}-{idx:02d}-{ts}"

    def _severity_level(self, severity):
        s = (severity or "").lower()
        if s == "critical":
            return "critical"
        if s == "high":
            return "warn"
        return "info"


class DispatchTickResult(BaseModel):
    advanced: int
    arrived: int


def advance_dispatches(db):
    now = datetime.datetime.utcnow()
    tracks = db.query(DispatchTrack).filter(DispatchTrack.status == "enroute").all()
    advanced = 0
    arrived = 0
    for t in tracks:
        elapsed_min = max(0.0, (now - t.last_tick_at).total_seconds() / 60.0)
        if t.eta_minutes and t.eta_minutes > 0:
            delta = elapsed_min / t.eta_minutes
        else:
            delta = 1.0
        if delta <= 0:
            delta = 0.15
        else:
            delta = max(delta, 0.15)
        t.progress = min(1.0, (t.progress or 0.0) + delta)
        t.current_lat = t.from_lat + (t.to_lat - t.from_lat) * t.progress
        t.current_lng = t.from_lng + (t.to_lng - t.from_lng) * t.progress
        t.last_tick_at = now
        advanced += 1
        if t.progress >= 1.0:
            t.status = "on_scene"
            t.current_lat = t.to_lat
            t.current_lng = t.to_lng
            arrived += 1
            ticket = (
                db.query(EmergencyTicket)
                .filter(EmergencyTicket.dispatch_id == t.id)
                .first()
            )
            if ticket is not None and ticket.status != "resolved":
                ticket.status = "on_scene"
                ticket.resolved_at = now
                db.add(
                    AlertLogEntry(
                        event_id=t.event_id,
                        channel="dispatch",
                        level="info",
                        title=f"Ticket {ticket.ticket_code} · on scene",
                        message=f"Unit arrived on scene after {t.eta_minutes:.1f} min ETA.",
                        ticket_id=ticket.id,
                    )
                )
    db.commit()
    return {"advanced": advanced, "arrived": arrived}
