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

## Setup Instructions

### Prerequisites

- **Python 3.9+** (for backend)
- **Flutter 3.11.5+** (for mobile)
- **Node.js** (optional, for web interface)
- **Git**
- **Google Antigravity API Key** (for agent orchestration)
- **Google Maps API Key** (for mapping features)
- **OpenWeatherMap API Key** (optional, for weather data)

### Backend Setup

1. **Navigate to backend directory:**
   ```bash
   cd backend
   ```

2. **Create Python virtual environment:**
   ```bash
   python -m venv venv
   ```

3. **Activate virtual environment:**
   - On Windows:
     ```bash
     venv\Scripts\activate
     ```
   - On macOS/Linux:
     ```bash
     source venv/bin/activate
     ```

4. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   ```

5. **Create `.env` file with credentials:**
   ```bash
   cp .env.example .env
   ```
   
   Edit `.env` and add:
   ```
   GOOGLE_GENAI_API_KEY=your_api_key
   OPENWEATHER_API_KEY=your_optional_api_key
   DATABASE_URL=sqlite:///ciro.db
   ```

6. **Run the backend server:**
   ```bash
   python main.py
   ```
   
   The API will be available at `http://localhost:8000`

### Mobile Setup

1. **Navigate to mobile directory:**
   ```bash
   cd mobile
   ```

2. **Install Flutter dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure API keys:**
   Create `lib/core/config.dart` with:
   ```dart
   const String GOOGLE_MAPS_API_KEY = 'your_api_key';
   const String BACKEND_URL = 'http://localhost:8000';
   ```

4. **Run the mobile app:**
   - **Android:**
     ```bash
     flutter run -d android
     ```
   - **iOS:**
     ```bash
     flutter run -d ios
     ```
   - **Web:**
     ```bash
     flutter run -d web
     ```

### Running the System

1. Start the backend service:
   ```bash
   cd backend
   source venv/bin/activate  # or venv\Scripts\activate on Windows
   python main.py
   ```

2. In a new terminal, start the mobile app:
   ```bash
   cd mobile
   flutter run
   ```

3. Access the application through the Flutter app or web interface

### Environment Variables

Create a `.env` file in the `backend` directory with the following variables:

```
GOOGLE_GENAI_API_KEY=sk-...
OPENWEATHER_API_KEY=your_key
DATABASE_URL=sqlite:///ciro.db
BACKEND_PORT=8000
```

**Note:** Never commit the `.env` file to version control. It's already included in `.gitignore`.

### Troubleshooting

- **Missing Python packages:** Ensure virtual environment is activated and run `pip install -r requirements.txt`
- **Flutter build errors:** Run `flutter clean` and then `flutter pub get`
- **API connectivity issues:** Verify API keys are correctly set in `.env` and configuration files
- **Database errors:** Delete `ciro.db` and restart the backend to reinitialize the database

## Project Structure

```
.
├── backend/              # FastAPI backend service
│   ├── app/
│   │   ├── agents/       # Multi-agent reasoning logic
│   │   ├── api/          # REST API endpoints
│   │   ├── core/         # Core models and business logic
│   │   ├── infra/        # Infrastructure (DB, LLM, data sources)
│   │   └── utils/        # Utility functions
│   ├── main.py          # Backend entry point
│   └── requirements.txt  # Python dependencies
│
├── mobile/              # Flutter mobile application
│   ├── lib/
│   │   ├── core/        # Core configuration and models
│   │   ├── features/    # Feature modules (dashboard, events, etc.)
│   │   ├── widgets/     # Reusable UI components
│   │   └── main.dart    # App entry point
│   ├── pubspec.yaml     # Flutter dependencies
│   ├── ios/             # iOS native code
│   └── android/         # Android native code
│
└── README.md            # This file
```

## Contributing

1. Create a feature branch from `main`
2. Make your changes with clear commit messages
3. Push to your fork and create a pull request
4. Ensure all changes are tested before submission

## License

This project is developed for educational and competitive purposes. All rights reserved.
