from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime

class SignalBase(BaseModel):
    source: str
    content: str
    lat: float
    lng: float
    credibility_score: Optional[float] = 0.5
    urgency_score: Optional[float] = 0.0
    is_suspicious: Optional[bool] = False

class SignalCreate(SignalBase):
    pass

class Signal(SignalBase):
    id: int
    timestamp: datetime
    is_fused: bool
    event_id: Optional[int] = None
    class Config:
        from_attributes = True

class CrisisEventBase(BaseModel):
    title: str
    description: str
    event_type: str
    confidence_score: float
    severity: str
    lat: float
    lng: float
    affected_population: Optional[int] = None
    expected_duration_hours: Optional[float] = None
    likely_evolution: Optional[str] = None
    contradiction_level: Optional[str] = "None"
    affected_radius_km: Optional[float] = None
    peak_impact_time: Optional[str] = None
    spread_risk: Optional[str] = None
    uncertainty_range: Optional[str] = None
    status: Optional[str] = "active"

class CrisisEventCreate(CrisisEventBase):
    pass

class CrisisEvent(CrisisEventBase):
    id: int
    created_at: datetime
    signals: List[Signal] = []
    class Config:
        from_attributes = True

class ResourceBase(BaseModel):
    name: str
    resource_type: str
    total_units: int
    available_units: int
    base_lat: float
    base_lng: float
    status: Optional[str] = "available"

class ResourceCreate(ResourceBase):
    pass

class Resource(ResourceBase):
    id: int
    class Config:
        from_attributes = True

class ResourceAllocationBase(BaseModel):
    event_id: int
    resource_id: int
    units_allocated: int
    travel_time_minutes: float
    priority_score: float
    reasoning: str

class ResourceAllocation(ResourceAllocationBase):
    id: int
    allocated_at: datetime
    class Config:
        from_attributes = True

class ActionSimulationBase(BaseModel):
    event_id: int
    action_type: str
    before_state: str
    action_description: str
    expected_after_state: str
    response_time_improvement: str
    congestion_impact: str
    resource_cost: str
    side_effects: str

class ActionSimulation(ActionSimulationBase):
    id: int
    created_at: datetime
    class Config:
        from_attributes = True

class StakeholderNotificationBase(BaseModel):
    event_id: int
    recipient: str
    subject: str
    message: str
    urgency: str
    channel: str

class StakeholderNotification(StakeholderNotificationBase):
    id: int
    created_at: datetime
    class Config:
        from_attributes = True

class VerificationLogBase(BaseModel):
    event_id: int
    verdict: str
    reasoning: str
    corrective_action: str
    updated_confidence: float
    retraction_message: Optional[str] = None

class VerificationLog(VerificationLogBase):
    id: int
    created_at: datetime
    class Config:
        from_attributes = True
