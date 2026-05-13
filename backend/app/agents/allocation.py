import json
from pydantic import BaseModel, Field
from app.core.models import CrisisEvent, Resource, ResourceAllocation
from app.agents.base import BaseAgent
from app.utils.geo import haversine

class Assignment(BaseModel):
    event_id: int
    resource_type: str
    units_to_allocate: int
    priority_score: float
    reasoning: str

class AllocationResponse(BaseModel):
    assignments: list[Assignment]
    trade_off_summary: str

class AllocationAgent(BaseAgent):
    def __init__(self):
        super().__init__("AllocationAgent")

    def run(self, db):
        self.traces = []
        events = db.query(CrisisEvent).all()
        resources = db.query(Resource).filter(Resource.available_units > 0).all()
        if not events or not resources:
            return {"message": "No work"}

        e_desc = [f"- ID {e.id}: {e.title}. Severity: {e.severity}." for e in events]
        r_desc = [f"- ID {r.id}: {r.name} ({r.resource_type}). {r.available_units} left." for r in resources]

        prompt = f"Allocate resources optimally:\n\nCrises:\n" + "\n".join(e_desc) + "\n\nResources:\n" + "\n".join(r_desc)

        status = "ok"
        try:
            res = json.loads(self.llm.generate(prompt, AllocationResponse, temp=0.2))
            assigns = res["assignments"]
        except Exception as e:
            self.logger.error(f"LLM fail: {e}")
            assigns, res = self._fallback(events, resources)
            status = "fallback"

        created = []
        for a in assigns:
            res_obj = db.query(Resource).filter(
                Resource.resource_type == a["resource_type"],
                Resource.available_units >= a["units_to_allocate"]
            ).first()

            if res_obj and a["units_to_allocate"] > 0:
                event = db.query(CrisisEvent).filter(CrisisEvent.id == a["event_id"]).first()
                if event:
                    dist = haversine(res_obj.base_lat, res_obj.base_lng, event.lat, event.lng)
                    time = (dist / 40.0) * 60
                    alloc = ResourceAllocation(
                        event_id=a["event_id"],
                        resource_id=res_obj.id,
                        units_allocated=a["units_to_allocate"],
                        travel_time_minutes=round(time, 1),
                        priority_score=a["priority_score"],
                        reasoning=a["reasoning"]
                    )
                    db.add(alloc)
                    res_obj.available_units -= a["units_to_allocate"]
                    created.append(alloc)
                    self._record(
                        db,
                        stage="allocate",
                        summary=(
                            f"{a['units_to_allocate']}× {a['resource_type']} → "
                            f"event #{a['event_id']} (priority {a['priority_score']:.2f})"
                        ),
                        reasoning=a["reasoning"],
                        event_id=a["event_id"],
                        status=status,
                        prompt=prompt,
                        decision={
                            "action": "allocate",
                            "event_id": a["event_id"],
                            "resource_id": res_obj.id,
                            "resource_name": res_obj.name,
                            "resource_type": a["resource_type"],
                            "units_to_allocate": a["units_to_allocate"],
                            "priority_score": a["priority_score"],
                            "travel_time_minutes": round(time, 1),
                            "distance_km": round(dist, 2),
                        },
                    )

        trade_off = res.get("trade_off_summary", "")
        if trade_off:
            self._record(
                db,
                stage="allocate",
                summary=f"Trade-off across {len(created)} allocation(s)",
                reasoning=trade_off,
                status=status,
                prompt=prompt,
                decision={
                    "action": "trade_off_summary",
                    "allocations_created": len(created),
                    "summary": trade_off,
                },
            )

        db.commit()
        return {"count": len(created), "summary": trade_off}

    def _fallback(self, events, resources):
        assigns = []
        if events:
            ev = events[0]
            for r in resources:
                assigns.append({
                    "event_id": ev.id,
                    "resource_type": r.resource_type,
                    "units_to_allocate": 1,
                    "priority_score": 0.5,
                    "reasoning": "Fallback mode"
                })
        return assigns, {"trade_off_summary": "Degraded mode"}
