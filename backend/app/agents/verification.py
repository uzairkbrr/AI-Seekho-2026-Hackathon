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
        self.traces = []
        events = db.query(CrisisEvent).filter(CrisisEvent.status == "active").all()
        if not events:
            return {"message": "No events"}

        results = []
        for e in events:
            sigs = db.query(Signal).filter(Signal.event_id == e.id).all()
            prompt = f"Verify event: {e.title}. Signals: " + str([s.content for s in sigs])
            status = "ok"
            try:
                res = json.loads(self.llm.generate(prompt, Verification, temp=0.1))
            except Exception as ex:
                self.logger.error(f"LLM fail: {ex}")
                res = self._fallback(e)
                status = "fallback"

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

            self._record(
                db,
                stage="verify",
                summary=(
                    f"Verdict: {res['verdict']} (confidence "
                    f"{res['updated_confidence']:.2f}) → {res['corrective_action']}"
                ),
                reasoning=res["reasoning"],
                event_id=e.id,
                status=status,
                prompt=prompt,
                decision={
                    "action": "verify_event",
                    "event_id": e.id,
                    "verdict": res["verdict"],
                    "updated_confidence": res["updated_confidence"],
                    "corrective_action": res["corrective_action"],
                    "retraction_message": res.get("retraction_message"),
                    "new_event_status": e.status,
                },
            )

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
