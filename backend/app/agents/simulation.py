import json
from pydantic import BaseModel, Field
from app.core.models import CrisisEvent, ActionSimulation
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

class SimulationAgent(BaseAgent):
    def __init__(self):
        super().__init__("SimulationAgent")

    def run(self, db):
        events = db.query(CrisisEvent).filter(CrisisEvent.status == "active").all()
        if not events:
            return {"message": "No events"}

        created = []
        for e in events:
            prompt = f"Simulate actions for: {e.title}. Type: {e.event_type}. Severity: {e.severity}."
            try:
                res = json.loads(self.llm.generate(prompt, SimulationResponse, temp=0.2))
                actions = res["actions"]
            except Exception as ex:
                self.logger.error(f"LLM fail: {ex}")
                actions = self._fallback()

            for a in actions:
                sim = ActionSimulation(
                    event_id=e.id,
                    action_type=a["action_type"],
                    before_state=a["before_state"],
                    action_description=a["action_description"],
                    expected_after_state=a["expected_after_state"],
                    response_time_improvement=a["response_time_improvement"],
                    congestion_impact=a["congestion_impact"],
                    resource_cost=a["resource_cost"],
                    side_effects=a["side_effects"]
                )
                db.add(sim)
                created.append(sim)

        db.commit()
        return {"count": len(created)}

    def _fallback(self):
        return [{
            "action_type": "alert",
            "before_state": "Degraded",
            "action_description": "Generic alert",
            "expected_after_state": "Public informed",
            "response_time_improvement": "N/A",
            "congestion_impact": "N/A",
            "resource_cost": "N/A",
            "side_effects": "None"
        }]
