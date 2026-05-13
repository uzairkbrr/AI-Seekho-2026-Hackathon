import json
from pydantic import BaseModel, Field
from app.core.models import Signal, CrisisEvent
from app.agents.base import BaseAgent
from app.utils.geo import haversine

class LLMResponse(BaseModel):
    event_type: str = Field(description="Classification")
    severity: str = Field(description="One of: Low, Medium, High, Critical.")
    contradiction_level: str = Field(description="One of: None, Low, High.")
    affected_population: int = Field(description="Estimated people affected.")
    expected_duration_hours: float = Field(description="Estimated duration in hours.")
    likely_evolution: str = Field(description="Evolution.")
    confidence_score: float = Field(description="0.0 to 1.0")
    affected_radius_km: float = Field(description="Radius in km.")
    peak_impact_time: str = Field(description="Peak time.")
    spread_risk: str = Field(description="One of: Low, Medium, High.")
    uncertainty_range: str = Field(description="Uncertainty.")

class FusionAgent(BaseAgent):
    def __init__(self):
        super().__init__("FusionAgent")

    def run(self, db):
        self.traces = []
        signals = db.query(Signal).filter(Signal.is_fused == False).all()
        if not signals:
            return []

        for s in signals:
            self._score(s)
        db.commit()

        clusters = self._cluster(signals)
        events = []

        for idx, cluster in enumerate(clusters):
            avg_cred = sum([s.credibility_score for s in cluster]) / len(cluster)
            cluster_preview = "\n".join(
                f"- [{s.source}] {s.content}" for s in cluster[:10]
            )
            if avg_cred < 0.3:
                self._record(
                    db,
                    stage="fuse",
                    summary=f"Skipped cluster {idx} ({len(cluster)} signals)",
                    reasoning=f"Avg credibility {avg_cred:.2f} < 0.3 threshold; treating as noise.",
                    status="skipped",
                    prompt=(
                        f"Cluster {idx} ({len(cluster)} signals, avg credibility "
                        f"{avg_cred:.2f}):\n\n{cluster_preview}"
                    ),
                    decision={
                        "action": "skip_cluster",
                        "cluster_size": len(cluster),
                        "avg_credibility": round(avg_cred, 3),
                        "threshold": 0.3,
                    },
                )
                continue

            status = "ok"
            prompt = f"Analyze these crisis signals:\n\n{cluster_preview}"
            try:
                res = json.loads(self.llm.generate(prompt, LLMResponse))
            except Exception as e:
                self.logger.error(f"LLM fail: {e}")
                res = self._fallback()
                status = "fallback"

            lat = sum([s.lat for s in cluster]) / len(cluster)
            lng = sum([s.lng for s in cluster]) / len(cluster)

            event = CrisisEvent(
                title=f"{res['event_type']} near ({lat:.2f}, {lng:.2f})",
                description=f"Analysis of {len(cluster)} signals.",
                event_type=res['event_type'],
                confidence_score=res['confidence_score'],
                severity=res['severity'],
                lat=lat,
                lng=lng,
                affected_population=res['affected_population'],
                expected_duration_hours=res['expected_duration_hours'],
                likely_evolution=res['likely_evolution'],
                contradiction_level=res['contradiction_level'],
                affected_radius_km=res['affected_radius_km'],
                peak_impact_time=res['peak_impact_time'],
                spread_risk=res['spread_risk'],
                uncertainty_range=res['uncertainty_range']
            )
            db.add(event)
            db.commit()
            db.refresh(event)

            for s in cluster:
                s.is_fused = True
                s.event_id = event.id

            reasoning = (
                f"Classified as {res['event_type']} ({res['severity']}, "
                f"confidence {res['confidence_score']:.2f}). "
                f"Likely evolution: {res['likely_evolution']}. "
                f"Spread risk: {res['spread_risk']}. "
                f"Uncertainty: {res['uncertainty_range']}."
            )
            decision = {
                "action": "create_event",
                "event_id": event.id,
                "cluster_size": len(cluster),
                "centroid": {"lat": round(lat, 4), "lng": round(lng, 4)},
                "classification": res,
            }
            self._record(
                db,
                stage="fuse",
                summary=f"Fused {len(cluster)} signals → event #{event.id}",
                reasoning=reasoning,
                event_id=event.id,
                status=status,
                prompt=prompt,
                decision=decision,
            )

            db.commit()
            events.append(event)

        return events

    def _score(self, s):
        c = s.content.lower()
        if s.source == "weather":
            s.credibility_score, s.urgency_score = 1.0, 0.5
        elif s.source in ["nasa_eonet", "usgs_earthquake"]:
            s.credibility_score, s.urgency_score = 1.0, 0.9
        elif s.source == "gdelt_news":
            s.credibility_score, s.urgency_score = 0.6, 0.3
        else:
            s.credibility_score, s.urgency_score = 0.5, 0.2

        if any(w in c for w in ["urgent", "severe", "killed", "emergency"]):
            s.urgency_score = min(1.0, s.urgency_score + 0.5)
        if any(w in c for w in ["fake", "prank", "hoax"]):
            s.is_suspicious = True
            s.credibility_score = 0.1

    def _cluster(self, signals):
        clusters = []
        visited = set()
        for i, s1 in enumerate(signals):
            if i in visited: continue
            cluster = [s1]
            visited.add(i)
            for j, s2 in enumerate(signals):
                if j not in visited and haversine(s1.lat, s1.lng, s2.lat, s2.lng) < 50.0:
                    cluster.append(s2)
                    visited.add(j)
            clusters.append(cluster)
        return clusters

    def _fallback(self):
        return {
            "event_type": "Unclassified (Degraded)",
            "severity": "Medium",
            "contradiction_level": "None",
            "affected_population": 0,
            "expected_duration_hours": 24.0,
            "likely_evolution": "Unknown",
            "confidence_score": 0.5,
            "affected_radius_km": 5.0,
            "peak_impact_time": "Unknown",
            "spread_risk": "Medium",
            "uncertainty_range": "High"
        }
