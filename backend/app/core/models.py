from sqlalchemy import Column, Integer, String, Float, DateTime, Boolean, ForeignKey
from sqlalchemy.orm import relationship
import datetime
from app.infra.db import Base

class Signal(Base):
    __tablename__ = "signals"
    id = Column(Integer, primary_key=True, index=True)
    source = Column(String, index=True)
    content = Column(String)
    content_hash = Column(String, index=True, nullable=True)
    lat = Column(Float)
    lng = Column(Float)
    timestamp = Column(DateTime, default=datetime.datetime.utcnow)
    is_fused = Column(Boolean, default=False)
    credibility_score = Column(Float, default=0.5)
    urgency_score = Column(Float, default=0.0)
    is_suspicious = Column(Boolean, default=False)
    event_id = Column(Integer, ForeignKey("crisis_events.id"), nullable=True)

class CrisisEvent(Base):
    __tablename__ = "crisis_events"
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String, index=True)
    description = Column(String)
    event_type = Column(String)
    confidence_score = Column(Float)
    severity = Column(String)
    lat = Column(Float)
    lng = Column(Float)
    affected_population = Column(Integer, nullable=True)
    expected_duration_hours = Column(Float, nullable=True)
    likely_evolution = Column(String, nullable=True)
    contradiction_level = Column(String, default="None")
    affected_radius_km = Column(Float, nullable=True)
    peak_impact_time = Column(String, nullable=True)
    spread_risk = Column(String, nullable=True)
    uncertainty_range = Column(String, nullable=True)
    status = Column(String, default="active")
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
    signals = relationship("Signal", backref="event")
    allocations = relationship("ResourceAllocation", backref="event")
    simulations = relationship("ActionSimulation", backref="event")
    notifications = relationship("StakeholderNotification", backref="event")
    verifications = relationship("VerificationLog", backref="event")

class Resource(Base):
    __tablename__ = "resources"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    resource_type = Column(String, index=True)
    total_units = Column(Integer)
    available_units = Column(Integer)
    base_lat = Column(Float)
    base_lng = Column(Float)
    status = Column(String, default="available")
    allocations = relationship("ResourceAllocation", backref="resource")

class ResourceAllocation(Base):
    __tablename__ = "resource_allocations"
    id = Column(Integer, primary_key=True, index=True)
    event_id = Column(Integer, ForeignKey("crisis_events.id"))
    resource_id = Column(Integer, ForeignKey("resources.id"))
    units_allocated = Column(Integer)
    travel_time_minutes = Column(Float)
    priority_score = Column(Float)
    reasoning = Column(String)
    allocated_at = Column(DateTime, default=datetime.datetime.utcnow)

class ActionSimulation(Base):
    __tablename__ = "action_simulations"
    id = Column(Integer, primary_key=True, index=True)
    event_id = Column(Integer, ForeignKey("crisis_events.id"))
    action_type = Column(String)
    before_state = Column(String)
    action_description = Column(String)
    expected_after_state = Column(String)
    response_time_improvement = Column(String)
    congestion_impact = Column(String)
    resource_cost = Column(String)
    side_effects = Column(String)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

class StakeholderNotification(Base):
    __tablename__ = "stakeholder_notifications"
    id = Column(Integer, primary_key=True, index=True)
    event_id = Column(Integer, ForeignKey("crisis_events.id"))
    recipient = Column(String, index=True)
    subject = Column(String)
    message = Column(String)
    urgency = Column(String)
    channel = Column(String)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)

class VerificationLog(Base):
    __tablename__ = "verification_logs"
    id = Column(Integer, primary_key=True, index=True)
    event_id = Column(Integer, ForeignKey("crisis_events.id"))
    verdict = Column(String)
    reasoning = Column(String)
    corrective_action = Column(String)
    updated_confidence = Column(Float)
    retraction_message = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.datetime.utcnow)
