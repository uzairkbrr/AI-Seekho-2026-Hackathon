# Crisis Intelligence and Response Orchestrator (CIRO)

> **Empowering National-Level Crisis Response through Agentic AI Orchestration.**

## Overview

The **Crisis Intelligence & Response Orchestrator (CIRO)** is an agentic AI system designed to detect, analyze, and coordinate responses to localized urban crises such as urban flooding, heatwaves, road blockages, accidents, and infrastructure failures. 

CIRO ingests signals from multiple sources, applies multi-agent reasoning to develop situational awareness, allocates constrained resources, simulates response actions, and visualizes their outcomes. The system is built to handle real-world challenges including conflicting signals, false positives, and simultaneous crises.

This prototype was developed for a competitive challenge, with strong emphasis on **Google Antigravity** for agent orchestration and a mandatory mobile application for practical field usage.

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

CIRO follows a modular, agent-driven architecture orchestrated primarily by Google Antigravity:

1. **Signal Ingestion Layer**: Text-based citizen reports, weather data, and traffic information
2. **Fusion and Analysis Agents**: Source credibility evaluation, geolocation, and contradiction resolution
3. **Reasoning Layer**: Detection, prediction, resource allocation, and action planning agents
4. **Simulation Engine**: Execution of traffic rerouting, emergency dispatch, alerts, and state updates
5. **Verification and Recovery Agent**: Handles inconsistencies and escalations
6. **Presentation Layer**: Flutter Mobile Application (primary interface)

Agent communication occurs through Antigravity’s shared memory and Workplans, providing full execution traceability.

## Technology Stack

- **Agent Orchestration**: Google Antigravity (core)
- **Mobile Application**: Flutter (Dart)
- **Backend Services**: Python/FastAPI (optional)
- **Mapping**: Google Maps Flutter SDK
- **State Management**: Riverpod
- **Mock Services**: Used as fallback where needed

## Google Antigravity Usage

Google Antigravity serves as the central orchestration engine. It is used for:

- Multi-agent Workplans managing the end-to-end crisis workflow
- Agent collaboration and handoffs
- Tool integration with mapping and simulation functions
- Comprehensive traces covering observations, reasoning steps, decisions, tool calls, and outcomes
- Recovery workflows for uncertain or conflicting scenarios

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
