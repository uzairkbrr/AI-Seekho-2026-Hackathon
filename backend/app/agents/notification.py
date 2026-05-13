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
        self.traces = []
        events = db.query(CrisisEvent).filter(CrisisEvent.status == "active").all()
        if not events:
            return {"message": "No events"}

        created = []
        for e in events:
            prompt = f"Generate alerts for: {e.title}. Type: {e.event_type}."
            status = "ok"
            try:
                res = json.loads(self.llm.generate(prompt, NotificationResponse, temp=0.2))
                notifs = res["notifications"]
            except Exception as ex:
                self.logger.error(f"LLM fail: {ex}")
                notifs = self._fallback(e)
                status = "fallback"

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
                self._record(
                    db,
                    stage="notify",
                    summary=f"[{n['urgency']}/{n['channel']}] → {n['recipient']}: {n['subject']}",
                    reasoning=n["message"],
                    event_id=e.id,
                    status=status,
                    prompt=prompt,
                    decision={
                        "action": "send_notification",
                        "event_id": e.id,
                        "recipient": n["recipient"],
                        "subject": n["subject"],
                        "urgency": n["urgency"],
                        "channel": n["channel"],
                        "message": n["message"],
                    },
                )

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
