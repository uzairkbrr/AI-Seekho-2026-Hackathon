"""Smoke test for Req 5: prove that /simulate actually mutates DB state.

Stubs out google-genai so it can run without a real API key, seeds an event +
allocation in a temporary sqlite database, runs SimulationAgent, and prints the
materialized RoadClosure / DispatchTrack / AlertZone rows.
"""
import os
import sys
import types
import tempfile

# --- Stub google.genai so the LLM import doesn't fail in this smoke env.
google_pkg = types.ModuleType("google")
genai_mod = types.ModuleType("google.genai")
types_mod = types.ModuleType("google.genai.types")


class _FakeClient:
    class _Models:
        def generate_content(self, *a, **kw):
            raise RuntimeError("LLM disabled in smoke test")

    def __init__(self, *a, **kw):
        self.models = self._Models()


genai_mod.Client = _FakeClient


class GenerateContentConfig:
    def __init__(self, **kw):
        pass


types_mod.GenerateContentConfig = GenerateContentConfig
sys.modules["google"] = google_pkg
sys.modules["google.genai"] = genai_mod
sys.modules["google.genai.types"] = types_mod

# Make the LLM constructor accept a missing key.
os.environ.setdefault("GEMINI_API_KEY", "smoke-test")

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
sys.path.insert(0, ROOT)

# Use a throwaway DB so we don't touch the real ciro.db.
tmp_db = tempfile.NamedTemporaryFile(suffix=".db", delete=False)
tmp_db.close()
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.infra import db as db_mod

db_mod.engine = create_engine(
    f"sqlite:///{tmp_db.name}", connect_args={"check_same_thread": False}
)
db_mod.SessionLocal = sessionmaker(bind=db_mod.engine, autocommit=False, autoflush=False)

from app.core import models
from app.agents.simulation import SimulationAgent, advance_dispatches

models.Base.metadata.create_all(bind=db_mod.engine)

S = db_mod.SessionLocal()

# Seed: one resource, one critical flood event, one allocation.
res = models.Resource(
    name="Ambulance A",
    resource_type="ambulance",
    total_units=3,
    available_units=2,
    base_lat=33.6844,
    base_lng=73.0479,
    status="available",
)
S.add(res)
S.commit()

ev = models.CrisisEvent(
    title="Urban Flood — F-6",
    description="Heavy ponding on Margalla Rd",
    event_type="urban_flooding",
    severity="Critical",
    confidence_score=0.82,
    lat=33.7295,
    lng=73.0930,
    affected_population=42000,
    expected_duration_hours=6.0,
    affected_radius_km=3.2,
    status="active",
)
S.add(ev)
S.commit()

alloc = models.ResourceAllocation(
    event_id=ev.id,
    resource_id=res.id,
    units_allocated=1,
    travel_time_minutes=8.5,
    priority_score=0.9,
    reasoning="Closest unit to flood epicenter",
)
S.add(alloc)
S.commit()

print(f"Seeded event={ev.id} resource={res.id} allocation={alloc.id}")
print(f"Pre-simulate: closures={S.query(models.RoadClosure).count()} "
      f"dispatches={S.query(models.DispatchTrack).count()} "
      f"zones={S.query(models.AlertZone).count()} "
      f"resource_status={res.status}")

result = SimulationAgent().run(S)
print(f"\nSimulationAgent.run() -> {result}")

S.refresh(res)
print(f"\nPost-simulate: closures={S.query(models.RoadClosure).count()} "
      f"dispatches={S.query(models.DispatchTrack).count()} "
      f"zones={S.query(models.AlertZone).count()} "
      f"resource_status={res.status}")

print("\n-- RoadClosures --")
for c in S.query(models.RoadClosure).all():
    print(
        f"  #{c.id} {c.label}: ({c.from_lat:.4f},{c.from_lng:.4f}) -> "
        f"({c.to_lat:.4f},{c.to_lng:.4f}) [{c.status}] — {c.reason}"
    )

print("\n-- DispatchTracks --")
for d in S.query(models.DispatchTrack).all():
    print(
        f"  #{d.id} res={d.resource_id} units={d.units} "
        f"({d.from_lat:.4f},{d.from_lng:.4f}) -> ({d.to_lat:.4f},{d.to_lng:.4f}) "
        f"cur=({d.current_lat:.4f},{d.current_lng:.4f}) "
        f"eta={d.eta_minutes}m progress={d.progress:.2f} [{d.status}]"
    )

print("\n-- AlertZones --")
for z in S.query(models.AlertZone).all():
    print(
        f"  #{z.id} center=({z.center_lat:.4f},{z.center_lng:.4f}) "
        f"radius={z.radius_km}km severity={z.severity} broadcast={z.broadcast_count}"
    )
    print(f"     msg: {z.message}")

# Force tick to simulate elapsed time, then re-run advance and inspect.
from datetime import datetime, timedelta
for d in S.query(models.DispatchTrack).all():
    d.last_tick_at = datetime.utcnow() - timedelta(minutes=5)
S.commit()

print(f"\nadvance_dispatches() -> {advance_dispatches(S)}")
for d in S.query(models.DispatchTrack).all():
    print(
        f"  #{d.id} cur=({d.current_lat:.4f},{d.current_lng:.4f}) "
        f"progress={d.progress:.2f} [{d.status}]"
    )

# Re-running simulate must be idempotent (no duplicate closures/dispatches/zones).
result2 = SimulationAgent().run(S)
print(f"\nSecond SimulationAgent.run() -> {result2}")
print(
    f"Idempotency: closures={S.query(models.RoadClosure).count()} "
    f"dispatches={S.query(models.DispatchTrack).count()} "
    f"zones={S.query(models.AlertZone).count()}"
)

S.close()
os.unlink(tmp_db.name)
print("\nSMOKE OK")
