from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.infra.db import get_db
from app.api import schemas
from app.core import models
from app.infra import sources
from app.agents.fusion import FusionAgent
from app.agents.allocation import AllocationAgent
from app.agents.simulation import SimulationAgent
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
