# Government Service Navigator (GSN)

Government Service Navigator is a multi-platform system for delivering and managing digital government services through:

- **Backend API** (ASP.NET Core + PostgreSQL)
- **Web dashboard** (React + Vite) for officers/admins
- **Mobile app** (Flutter) for citizens
- **Agent layer** for AI-assisted workflows

---

## Repository Structure

```text
government-service-navigator/
├── backend/                      # ASP.NET Core Web API (single backend, all 4 components + agents)
│   ├── src/
│   │   ├── GSN.Api/               # Controllers, Program.cs, appsettings
│   │   ├── GSN.Application/       # Services, DTOs, business logic per component (A/B/C/D)
│   │   ├── GSN.Domain/            # Entities: Services, Applications, VerificationTasks, Payments, etc.
│   │   ├── GSN.Infrastructure/    # EF Core, PostgreSQL DbContext, migrations
│   │   └── GSN.Agents/            # The 4 agentic AI agents + orchestration + tool functions
│   ├── tests/
│   │   ├── GSN.Api.Tests/
│   │   └── GSN.Agents.Tests/      # golden-case agent tests
│   └── GSN.sln
│
├── web/                           # React officer + admin dashboard
│   ├── src/
│   ├── public/
│   ├── package.json
│   └── vite.config.ts
│
├── mobile/                        # Flutter citizen app
│   ├── lib/
│   ├── android/
│   ├── ios/
│   └── pubspec.yaml
│
├── docs/                          # ADRs, diagrams, testing/eval/perf/deployment reports
│   ├── adr/
│   ├── diagrams/
│   └── reports/
│
├── .github/workflows/             # CI: one workflow per app, or one matrix workflow
│   └── ci.yml
│
├── docker-compose.yml             # Postgres + API locally
├── .gitignore
└── README.md
```

---

## Tech Stack

- **Backend:** ASP.NET Core Web API, Entity Framework Core, PostgreSQL
- **Web:** React, TypeScript, Vite
- **Mobile:** Flutter (Dart)
- **DevOps:** GitHub Actions, Docker Compose

---

## Prerequisites

Install these before setup:

- [Git](https://git-scm.com/)
- [Docker Desktop](https://www.docker.com/products/docker-desktop/)
- [.NET SDK (8.0+ recommended)](https://dotnet.microsoft.com/en-us/download)
- [Node.js (18+ recommended)](https://nodejs.org/)
- [Flutter SDK](https://docs.flutter.dev/get-started/install)

Optional but useful:

- PostgreSQL client (e.g., pgAdmin / psql)
- VS Code / Rider / Visual Studio

---

## Quick Start

### 1) Clone the repository

```bash
git clone https://github.com/Krishmal2004/Government_Service_Navigator.git
cd Government_Service_Navigator
```

### 2) Start infrastructure (PostgreSQL)

From repo root:

```bash
docker compose up -d
```

This starts services defined in `docker-compose.yml` (typically PostgreSQL for local development).

---

## Backend Setup (ASP.NET Core API)

### 1) Configure environment

Go to backend API project and configure `appsettings.Development.json` (or environment variables), especially:

- PostgreSQL connection string
- Any API keys/secrets needed by `GSN.Agents`

> Never commit real secrets. Use environment variables or secret managers.

### 2) Restore and build

```bash
cd backend
dotnet restore
dotnet build
```

### 3) Apply database migrations

If migrations already exist:

```bash
dotnet ef database update --project src/GSN.Infrastructure --startup-project src/GSN.Api
```

If `dotnet ef` is not installed:

```bash
dotnet tool install --global dotnet-ef
```

### 4) Run API

```bash
dotnet run --project src/GSN.Api
```

API should be available on the port configured in `GSN.Api` launch settings (commonly `https://localhost:7xxx` / `http://localhost:5xxx`).

---

## Web Setup (React Dashboard)

```bash
cd web
npm install
npm run dev
```

The Vite dev server will start (commonly `http://localhost:5173`).

If needed, create `.env` in `web/` for API base URL:

```env
VITE_API_BASE_URL=http://localhost:5000
```

---

## Mobile Setup (Flutter Citizen App)

```bash
cd mobile
flutter pub get
flutter run
```

For platform-specific setup:

- Android: ensure Android SDK/emulator is configured
- iOS: run on macOS with Xcode installed

If needed, configure backend endpoint in app config (e.g., `lib/config` or env strategy used in your project).

---

## Running Tests

### Backend/API tests

```bash
cd backend
dotnet test
```

### Agent tests (golden cases)

```bash
cd backend
dotnet test tests/GSN.Agents.Tests
```

### Web tests (if configured)

```bash
cd web
npm test
```

### Flutter tests

```bash
cd mobile
flutter test
```

---

## CI/CD

GitHub Actions workflows are under:

```text
.github/workflows/
```

Typical pipeline tasks:

- Build backend, web, mobile
- Run automated tests
- Validate lint/format (if configured)

---

## Development Notes

- Keep architectural decisions in `docs/adr/`
- Store diagrams in `docs/diagrams/`
- Store test/evaluation/performance/deployment outputs in `docs/reports/`
- Follow clean layering:
  - `GSN.Domain` → core business entities
  - `GSN.Application` → use cases/services
  - `GSN.Infrastructure` → persistence/external integrations
  - `GSN.Api` → HTTP API surface
  - `GSN.Agents` → AI agents and orchestration

---

## Troubleshooting

### Docker/Postgres not starting
- Check Docker Desktop is running
- Run `docker compose logs` for details
- Ensure port conflicts are resolved

### API cannot connect to DB
- Verify connection string host/port/user/password
- Confirm DB container is healthy
- Re-run migrations

### CORS issues between web and API
- Add web dev URL to backend CORS policy
- Confirm API base URL in web `.env`

### Flutter cannot reach local API
- Android emulator often uses `10.0.2.2` instead of `localhost`
- Physical devices need machine LAN IP + open firewall/ports

---

## License

Add your project license here (e.g., MIT, Apache-2.0, proprietary).
