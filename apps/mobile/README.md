# THCP Mobile (Flutter)

## Prerequisites

Install Flutter 3.16+ and run platform scaffolding once:

```bash
cd mobile
flutter create . --project-name thcp_mobile --org et.thcp
flutter pub get
```

## Run against local API

```bash
# Android emulator → host machine API
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1

# Linux desktop
flutter run --dart-define=API_BASE_URL=http://localhost:3000/api/v1
```

Ensure the NestJS API and Docker Postgres/Redis are running (see repo root `docker compose`).
