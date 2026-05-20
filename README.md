# Delala

Monorepo for the Delala (THCP) platform: NestJS API, Flutter mobile app, and local infrastructure via Docker Compose.

## Structure

- `backend/` — NestJS API (`npm install`, `npm run start:dev`)
- `mobile/` — Flutter app (see [mobile/README.md](mobile/README.md))
- `docker-compose.yml` — PostgreSQL and Redis for local development

## Quick start

1. Copy environment variables: `cp .env.example .env`
2. Start databases: `docker compose up -d postgres redis`
3. API: `cd backend && npm install && npm run start:dev`
4. Mobile: see [mobile/README.md](mobile/README.md)
