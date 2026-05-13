import json
from pydantic import BaseModel, Field
from app.core.models import CrisisEvent, StakeholderNotification
from app.agents.base import BaseAgent

class Notification(BaseModel):
    recipient: str
    subject: str
    message: str
    urgency: str
    channel: str

class NotificationResponse(BaseModel):
    notifications: list[Notification]

class NotificationAgent(BaseAgent):
    def __init__(self):
        super().__init__("NotificationAgent")

    def run(self, db):
        events = db.query(CrisisEvent).filter(CrisisEvent.status == "active").all()
        if not events:
            return {"message": "No events"}

        created = []
        for e in events:
            prompt = f"Generate alerts for: {e.title}. Type: {e.event_type}."
            try:
                res = json.loads(self.llm.generate(prompt, NotificationResponse, temp=0.2))
                notifs = res["notifications"]
            except Exception as ex:
                self.logger.error(f"LLM fail: {ex}")
                notifs = self._fallback(e)

            for n in notifs:
                obj = StakeholderNotification(
                    event_id=e.id,
                    recipient=n["recipient"],
                    subject=n["subject"],
                    message=n["message"],
                    urgency=n["urgency"],
                    channel=n["channel"]
                )
                db.add(obj)
                created.append(obj)

        db.commit()
        return {"count": len(created)}

    def _fallback(self, e):
        return [{
            "recipient": "all",
            "subject": f"Alert: {e.title}",
            "message": "Degraded mode fallback",
            "urgency": "Urgent",
            "channel": "Dashboard"
        }]
