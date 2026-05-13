# Crisis Intelligence and Response Orchestrator (CIRO)

> **Empowering National-Level Crisis Response through Agentic AI Orchestration.**

## Overview

The **Crisis Intelligence & Response Orchestrator (CIRO)** is an agentic AI system designed to detect, analyze, and coordinate responses to localized urban crises such as urban flooding, heatwaves, road blockages, accidents, and infrastructure failures. 

CIRO ingests signals from multiple sources, applies multi-agent reasoning to develop situational awareness, allocates constrained resources, simulates response actions, and visualizes their outcomes. The system is built to handle real-world challenges including conflicting signals, false positives, and simultaneous crises.

This prototype was developed for a competitive challenge, with strong emphasis on a **structured multi-agent pipeline** for crisis orchestration and a mandatory mobile application for practical field usage.

## Key Features

- Multi-source signal ingestion with credibility scoring
- Crisis detection, classification, severity assessment, and confidence scoring
- Impact prediction and evolution forecasting
- Constrained resource allocation with prioritization
- Coordinated action planning and realistic simulation
- Recovery mechanisms for false positives and conflicting signals
- Multi-crisis coordination and resource trade-off reasoning
- Stakeholder-specific notification generation
- Interactive before/after impact visualization

## System Architecture

CIRO is built as a **structured pipeline** of specialized agents, each exposed as a FastAPI endpoint and driven in sequence by the mobile Pipeline control surface:

1. **Signal Ingestion Layer** (`/ingest`): Text-based citizen reports, weather data, and traffic information
2. **Fusion and Analysis Agent** (`/fuse`): Source credibility scoring, spatial clustering, and LLM-based event classification
3. **Allocation Agent** (`/allocate`): Constrained resource assignment with priority scoring and trade-off reasoning
4. **Simulation Agent** (`/simulate`): Action planning, dispatch materialization, alert zones, and road closures
5. **Notification Agent** (`/notify`): Stakeholder-specific communications across channels and urgency levels
6. **Verification Agent** (`/verify`): False-positive detection, escalation, and recovery
7. **Presentation Layer**: Flutter Mobile Application (primary interface)

Agents do not call each other directly. They share state through a SQLite database (SQLAlchemy ORM), and every decision, fallback, and skip is written to an `AgentTrace` row tagged with stage, agent, event, summary, and reasoning. This gives the mobile Pipeline tab full step-by-step traceability and makes each stage independently re-runnable.

## Technology Stack

- **Agent Pipeline**: Python/FastAPI — one HTTP endpoint per agent stage
- **Agent Reasoning**: Google Gemini via the project's `LLM` wrapper, with deterministic fallbacks for degraded mode
- **Shared State & Traces**: SQLite + SQLAlchemy, with an `AgentTrace` table recording every stage decision
- **Mobile Application**: Flutter (Dart)
- **Mapping**: Google Maps Flutter SDK
- **State Management**: Riverpod
- **Mock Services**: Used as fallback where real APIs are unavailable

## Pipeline Orchestration

The mobile **Pipeline** tab drives the end-to-end workflow by calling each backend stage in order. There is no hidden orchestrator — the pipeline is the contract:

- **Re-runnable stages**: Every stage is idempotent on already-processed records (e.g. `is_fused`, existing dispatches/zones/closures are not duplicated), so operators can re-run a stage without corrupting state.
- **Shared memory via DB**: Each agent reads its inputs and writes its outputs to the shared database. The next stage picks up from there.
- **Full traceability**: Every agent emits `AgentTrace` rows with `stage`, `agent`, `event_id`, `summary`, `reasoning`, and `status` (`ok` / `fallback` / `skipped`). The mobile Pipeline view fetches these per stage to render the live reasoning timeline.
- **Recovery and escalation**: The Verification stage can flip events to `verified`, `retracted`, or `escalated` based on signal evidence, closing the loop on false positives and conflicting reports.
- **Graceful degradation**: When an LLM call fails, each agent has a deterministic fallback path and tags the trace as `fallback` so the UI can surface the degraded decision.

## Data Sources

**Citizen Reports / Social Media Signals**  
Best suited for demonstration: Direct text input through the mobile application. Users can enter complaints, social media-style posts, or emergency reports (in English or Urdu). This approach provides full control, reliability, and ease of testing various scenarios.

**Weather Data**  
Integration with real weather APIs (e.g., OpenWeatherMap) is supported. The system falls back to realistic mock data when API keys are not configured or services are unavailable.

**Traffic and Mapping**  
Uses Google Maps Flutter SDK for visualization. Real-time traffic layers and routing are enabled where API access is available, with simulated congestion overlays used as fallback.

**Fallback Mechanism**  
The system automatically switches to comprehensive mock datasets when real services are not available. All mock data is synthetic, realistic, and clearly labeled.

## License

This project is developed for educational and competitive purposes. All rights reserved.
