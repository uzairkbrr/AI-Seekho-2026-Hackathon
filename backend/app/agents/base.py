import json

from app.core.models import AgentTrace
from app.infra.llm import LLM
from app.utils.log import get_logger


def _serialize_decision(decision):
    if decision is None:
        return None
    if isinstance(decision, str):
        return decision
    try:
        return json.dumps(decision, indent=2, default=str, ensure_ascii=False)
    except (TypeError, ValueError):
        return str(decision)


class BaseAgent:
    def __init__(self, name):
        self.name = name
        self.logger = get_logger(name)
        self.llm = LLM()
        self.traces: list[dict] = []

    def _record(
        self,
        db,
        stage,
        summary,
        reasoning,
        event_id=None,
        status="ok",
        prompt=None,
        decision=None,
    ):
        summary = (summary or "").strip()
        reasoning = (reasoning or "").strip()
        prompt_text = (prompt or "").strip() or None
        decision_text = _serialize_decision(decision)
        if decision_text is not None:
            decision_text = decision_text.strip() or None

        row = AgentTrace(
            agent=self.name,
            stage=stage,
            event_id=event_id,
            summary=summary[:500],
            reasoning=reasoning[:4000],
            prompt=prompt_text[:16000] if prompt_text else None,
            decision=decision_text[:16000] if decision_text else None,
            status=status,
        )
        db.add(row)
        self.logger.info(f"[{stage}] {summary} | {reasoning[:200]}")
        self.traces.append(
            {
                "agent": self.name,
                "stage": stage,
                "event_id": event_id,
                "summary": summary,
                "reasoning": reasoning,
                "prompt": prompt_text,
                "decision": decision_text,
                "status": status,
            }
        )
