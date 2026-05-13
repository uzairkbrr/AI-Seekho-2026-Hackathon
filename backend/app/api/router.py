from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from app.infra.db import get_db
from app.api import schemas
from app.core import models
from app.infra import sources
from app.agents.fusion import FusionAgent
from app.agents.allocation import AllocationAgent
from app.agents.simulation import SimulationAgent, advance_dispatches
from app.agents.notification import NotificationAgent
from app.agents.verification import VerificationAgent

router = APIRouter()

@router.get("/health")
def health(db: Session = Depends(get_db)):
    return {"status": "ok"}

@router.post("/ingest")
async def ingest(lat: float = 33.6844, lng: float = 73.0479, db: Session = Depends(get_db)):
    return await sources.ingest_all(db, lat, lng)

@router.post("/fuse", response_model=list[schemas.CrisisEvent])
def fuse(db: Session = Depends(get_db)):
    return FusionAgent().run(db)

@router.post("/allocate")
def allocate(db: Session = Depends(get_db)):
    return AllocationAgent().run(db)

@router.post("/simulate")
def simulate(db: Session = Depends(get_db)):
    return SimulationAgent().run(db)

@router.post("/simulate/tick")
def simulate_tick(db: Session = Depends(get_db)):
    return advance_dispatches(db)

@router.post("/notify")
def notify(db: Session = Depends(get_db)):
    return NotificationAgent().run(db)

@router.post("/verify")
def verify(db: Session = Depends(get_db)):
    return VerificationAgent().run(db)

@router.get("/signals", response_model=list[schemas.Signal])
def get_signals(db: Session = Depends(get_db)):
    return db.query(models.Signal).all()

@router.get("/events", response_model=list[schemas.CrisisEvent])
def get_events(db: Session = Depends(get_db)):
    return db.query(models.CrisisEvent).all()

@router.get("/resources", response_model=list[schemas.Resource])
def get_resources(db: Session = Depends(get_db)):
    return db.query(models.Resource).all()

@router.post("/resources/init")
def init_res(db: Session = Depends(get_db)):
    if db.query(models.Resource).count() > 0:
        return {"msg": "Already init"}
    fleet = [
        models.Resource(name="Ambulance A", resource_type="ambulance", total_units=3, available_units=3, base_lat=33.6844, base_lng=73.0479),
        models.Resource(name="Police A", resource_type="police", total_units=4, available_units=4, base_lat=33.6938, base_lng=73.0652),
        models.Resource(name="Rescue A", resource_type="rescue_team", total_units=2, available_units=2, base_lat=33.6600, base_lng=73.0400),
    ]
    for r in fleet: db.add(r)
    db.commit()
    return {"msg": "Done", "count": len(fleet)}

@router.get("/closures", response_model=list[schemas.RoadClosure])
def get_closures(event_id: int | None = Query(default=None), db: Session = Depends(get_db)):
    q = db.query(models.RoadClosure)
    if event_id is not None:
        q = q.filter(models.RoadClosure.event_id == event_id)
    return q.order_by(models.RoadClosure.id.desc()).all()

@router.get("/dispatches", response_model=list[schemas.DispatchTrack])
def get_dispatches(event_id: int | None = Query(default=None), db: Session = Depends(get_db)):
    q = db.query(models.DispatchTrack)
    if event_id is not None:
        q = q.filter(models.DispatchTrack.event_id == event_id)
    return q.order_by(models.DispatchTrack.id.desc()).all()

@router.get("/alert-zones", response_model=list[schemas.AlertZone])
def get_alert_zones(event_id: int | None = Query(default=None), db: Session = Depends(get_db)):
    q = db.query(models.AlertZone)
    if event_id is not None:
        q = q.filter(models.AlertZone.event_id == event_id)
    return q.order_by(models.AlertZone.id.desc()).all()

@router.get("/simulations", response_model=list[schemas.ActionSimulation])
def get_simulations(event_id: int | None = Query(default=None), db: Session = Depends(get_db)):
    q = db.query(models.ActionSimulation)
    if event_id is not None:
        q = q.filter(models.ActionSimulation.event_id == event_id)
    return q.order_by(models.ActionSimulation.id.desc()).all()

@router.get("/notifications", response_model=list[schemas.StakeholderNotification])
def get_notifications(event_id: int | None = Query(default=None), db: Session = Depends(get_db)):
    q = db.query(models.StakeholderNotification)
    if event_id is not None:
        q = q.filter(models.StakeholderNotification.event_id == event_id)
    return q.order_by(models.StakeholderNotification.id.desc()).all()

@router.get("/tickets", response_model=list[schemas.EmergencyTicket])
def get_tickets(event_id: int | None = Query(default=None), db: Session = Depends(get_db)):
    q = db.query(models.EmergencyTicket)
    if event_id is not None:
        q = q.filter(models.EmergencyTicket.event_id == event_id)
    return q.order_by(models.EmergencyTicket.id.desc()).all()

@router.post("/tickets/{ticket_id}/resolve", response_model=schemas.EmergencyTicket)
def resolve_ticket(ticket_id: int, db: Session = Depends(get_db)):
    t = db.query(models.EmergencyTicket).filter(models.EmergencyTicket.id == ticket_id).first()
    if t is None:
        raise HTTPException(status_code=404, detail="Ticket not found")
    if t.status != "resolved":
        t.status = "resolved"
        t.resolved_at = datetime.utcnow()
        db.add(
            models.AlertLogEntry(
                event_id=t.event_id,
                channel=t.category,
                level="info",
                title=f"Ticket {t.ticket_code} · resolved",
                message=f"Ticket marked resolved by operator.",
                ticket_id=t.id,
            )
        )
        db.commit()
        db.refresh(t)
    return t

@router.get("/alert-log", response_model=list[schemas.AlertLogEntry])
def get_alert_log(
    event_id: int | None = Query(default=None),
    channel: str | None = Query(default=None),
    limit: int = Query(default=200, le=1000),
    db: Session = Depends(get_db),
):
    q = db.query(models.AlertLogEntry)
    if event_id is not None:
        q = q.filter(models.AlertLogEntry.event_id == event_id)
    if channel is not None:
        q = q.filter(models.AlertLogEntry.channel == channel)
    return q.order_by(models.AlertLogEntry.id.desc()).limit(limit).all()

@router.get("/traces", response_model=list[schemas.AgentTrace])
def get_traces(
    stage: str | None = Query(default=None),
    agent: str | None = Query(default=None),
    event_id: int | None = Query(default=None),
    since: datetime | None = Query(default=None),
    limit: int = Query(default=200, le=1000),
    db: Session = Depends(get_db),
):
    q = db.query(models.AgentTrace)
    if stage is not None:
        q = q.filter(models.AgentTrace.stage == stage)
    if agent is not None:
        q = q.filter(models.AgentTrace.agent == agent)
    if event_id is not None:
        q = q.filter(models.AgentTrace.event_id == event_id)
    if since is not None:
        # DB column is naive UTC (datetime.utcnow); normalize tz-aware input.
        if since.tzinfo is not None:
            since = since.astimezone(timezone.utc).replace(tzinfo=None)
        q = q.filter(models.AgentTrace.created_at >= since)
    return q.order_by(models.AgentTrace.id.desc()).limit(limit).all()
