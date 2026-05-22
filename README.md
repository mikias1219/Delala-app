# Delala

Monorepo: **NestJS API** + **Flutter mobile** for rentals and domestic workers in Addis Ababa.

## Structure

```
apps/
  api/       # NestJS — one folder per domain under src/modules/
  mobile/    # Flutter — one folder per feature under lib/features/
infra/       # docker-compose (Postgres, Redis)
scripts/     # dev tooling
```

### Add a backend feature

1. Create `apps/api/src/modules/<name>/` with `*.module.ts`, `*.controller.ts`, `*.service.ts`, `dto/`, `entities/`
2. Export from `apps/api/src/modules/index.ts`
3. Register in `apps/api/src/app.module.ts`

### Add a mobile feature

1. Create `apps/mobile/lib/features/<name>/` with `data/<name>_api.dart`, `presentation/`, `providers/`
2. Use `httpClientProvider` from `core/network/http_client.dart` — do not create a second Dio client
3. Add route in `lib/router/app_router.dart`

## Ports (change in `.env` if needed)

| Service    | Port |
|-----------|------|
| API       | 3010 |
| Postgres  | 5435 |
| Redis     | 6381 |

## Commands

```bash
cp .env.example .env
chmod +x scripts/*.sh

./scripts/dev.sh              # infra + API + seed + tests
./scripts/dev.sh --mobile     # + Flutter on USB phone
./scripts/dev.sh --stop       # stop all

./scripts/build-mobile.sh              # debug APK (~1–3 min; first build ~15 min)
./scripts/build-mobile.sh --release    # release APK for sharing
./scripts/build-mobile.sh --install

npm run dev                   # same as ./scripts/dev.sh
```

### First-time Android APK build

```bash
sudo apt install -y openjdk-17-jdk
./scripts/setup-android.sh
```

Phone and PC on the **same Wi‑Fi**. Dev login: `0911000002` — OTP shown on screen.

## CI

GitHub Actions (`.github/workflows/ci.yml`): API build + e2e, Flutter analyze + format check.
