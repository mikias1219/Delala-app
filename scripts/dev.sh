#!/usr/bin/env bash
# Delala — one command to run the full stack (infra + API + seed + tests).
#
# Usage:
#   ./scripts/dev.sh              # start everything
#   ./scripts/dev.sh --mobile     # also launch Flutter on phone
#   ./scripts/dev.sh --stop       # stop API + Docker
#   ./scripts/dev.sh --no-seed    # skip seed
#   ./scripts/dev.sh --no-test    # skip e2e tests
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
API_DIR="$ROOT/apps/api"
MOBILE_DIR="$ROOT/apps/mobile"
if [[ -f "$ROOT/.env" ]]; then
  COMPOSE="docker compose -f $ROOT/infra/docker-compose.yml --env-file $ROOT/.env"
else
  COMPOSE="docker compose -f $ROOT/infra/docker-compose.yml"
fi
RUN_DIR="$ROOT/.dev"
PID_FILE="$RUN_DIR/api.pid"
LOG_FILE="$RUN_DIR/api.log"

RUN_MOBILE=false
RUN_SEED=true
RUN_TEST=true
STOP=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mobile) RUN_MOBILE=true ;;
    --no-seed) RUN_SEED=false ;;
    --no-test) RUN_TEST=false ;;
    --stop) STOP=true ;;
    -h|--help)
      grep '^#' "$0" | head -12 | sed 's/^# \?//'
      exit 0
      ;;
    *) echo "Unknown: $1" >&2; exit 1 ;;
  esac
  shift
done

load_env() {
  [[ -f "$ROOT/.env" ]] && set -a && source "$ROOT/.env" && set +a
  PORT="${PORT:-3010}"
  PREFIX="${API_PREFIX:-api/v1}"
  API_HEALTH="http://127.0.0.1:${PORT}/${PREFIX}/health"
}

stop_api() {
  [[ -f "$PID_FILE" ]] || return 0
  local pid
  pid="$(cat "$PID_FILE")"
  kill -0 "$pid" 2>/dev/null && kill "$pid" 2>/dev/null || true
  sleep 1
  kill -9 "$pid" 2>/dev/null || true
  rm -f "$PID_FILE"
}

stop_stack() {
  stop_api
  $COMPOSE down
  echo "Stopped."
}

start_infra() {
  echo "▶ Postgres (${DATABASE_HOST_PORT:-5435}) + Redis (${REDIS_PORT:-6381})"
  $COMPOSE up -d postgres redis
  for _ in {1..30}; do
    pg=$(docker inspect -f '{{.State.Health.Status}}' delala-postgres 2>/dev/null || echo x)
    rd=$(docker inspect -f '{{.State.Health.Status}}' delala-redis 2>/dev/null || echo x)
    [[ "$pg" == healthy && "$rd" == healthy ]] && return 0
    sleep 1
  done
  echo "Docker health timeout" >&2; exit 1
}

api_up() {
  curl -sf "$API_HEALTH" >/dev/null 2>&1
}

start_api() {
  mkdir -p "$RUN_DIR"
  if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null && api_up; then
    echo "▶ API already on :$PORT"; return 0
  fi
  stop_api
  api_up && { echo "▶ API already on :$PORT"; return 0; }
  echo "▶ API → :$PORT (log: $LOG_FILE)"
  (cd "$API_DIR" && npm run start:dev) >>"$LOG_FILE" 2>&1 &
  echo $! >"$PID_FILE"
  for _ in {1..90}; do
    api_up && { echo "  Ready $API_HEALTH"; return 0; }
    kill -0 "$(cat "$PID_FILE")" 2>/dev/null || { tail -20 "$LOG_FILE" >&2; exit 1; }
    sleep 1
  done
  echo "API timeout — see $LOG_FILE" >&2; exit 1
}

run_seed() {
  echo "▶ Seed"
  (cd "$API_DIR" && npm run seed)
}

run_tests() {
  echo "▶ E2E tests"
  (cd "$API_DIR" && npm run test:e2e)
}

run_mobile() {
  local ip url
  ip="${LAN_IP:-$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}')}"
  url="http://${ip}:${PORT}/${PREFIX}"
  echo "▶ Flutter → $url"
  (cd "$MOBILE_DIR" && flutter pub get && flutter run --dart-define=API_BASE_URL="$url")
}

print_done() {
  local ip
  ip="${LAN_IP:-$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}')}"
  cat <<EOF

══════════════════════════════════════════
  Delala running
  API:     http://127.0.0.1:${PORT}/${PREFIX}
  Phone:   http://${ip}:${PORT}/${PREFIX}
  Logs:    tail -f $LOG_FILE
  Stop:    ./scripts/dev.sh --stop
  APK:     ./scripts/build-mobile.sh
  Login:   0911000002 (Dev OTP on screen)
══════════════════════════════════════════
EOF
}

main() {
  load_env
  $STOP && stop_stack && exit 0
  start_infra
  start_api
  $RUN_SEED && run_seed
  $RUN_TEST && run_tests
  print_done
  $RUN_MOBILE && run_mobile
}

main "$@"
