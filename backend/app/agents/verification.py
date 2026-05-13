import json
from pydantic import BaseModel, Field
from app.core.models import CrisisEvent, Signal, VerificationLog
from app.agents.base import BaseAgent

class Verification(BaseModel):
    verdict: str
    reasoning: str
    corrective_action: str
    updated_confidence: float
    retraction_message: str

class VerificationAgent(BaseAgent):
    def __init__(self):
        super().__init__("VerificationAgent")

    def run(self, db):
        events = db.query(CrisisEvent).filter(CrisisEvent.status == "active").all()
        if not events:
            return {"message": "No events"}

        results = []
        for e in events:
            sigs = db.query(Signal).filter(Signal.event_id == e.id).all()
            prompt = f"Verify event: {e.title}. Signals: " + str([s.content for s in sigs])
            try:
                res = json.loads(self.llm.generate(prompt, Verification, temp=0.1))
            except Exception as ex:
                self.logger.error(f"LLM fail: {ex}")
                res = self._fallback(e)

            log = VerificationLog(
                event_id=e.id,
                verdict=res["verdict"],
                reasoning=res["reasoning"],
                corrective_action=res["corrective_action"],
                updated_confidence=res["updated_confidence"],
                retraction_message=res["retraction_message"]
            )
            db.add(log)
            
            if res["verdict"] == "confirmed":
                e.status = "verified"
            elif res["verdict"] == "false_positive":
                e.status = "retracted"
            elif res["verdict"] == "escalate":
                e.status = "escalated"
                e.severity = "Critical"

            results.append({"id": e.id, "verdict": res["verdict"]})

        db.commit()
        return results

    def _fallback(self, e):
        return {
            "verdict": "needs_verification",
            "reasoning": "Fallback mode",
            "corrective_action": "Manual check",
            "updated_confidence": e.confidence_score,
            "retraction_message": "N/A"
        }
