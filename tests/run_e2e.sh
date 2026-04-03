#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
E2E_DIR="${SCRIPT_DIR}/e2e"
BATS_DIR="${E2E_DIR}/bats"
COMPOSE_CMD="docker compose -p e2e -f ${E2E_DIR}/docker-compose.e2e.yaml"

# Always collect logs and tear down on exit
cleanup() {
  echo "=== Collecting container logs ==="
  mkdir -p "${E2E_DIR}/logs"
  $COMPOSE_CMD logs > "${E2E_DIR}/logs/compose.log" 2>&1 || true
  $COMPOSE_CMD logs 2>&1 || true
  echo "=== Tearing down E2E test services ==="
  $COMPOSE_CMD down -v 2>&1 || true
}
trap cleanup EXIT

echo "=== E2E Test Runner ==="

# Step 1: Install BATS if not present
if [ ! -d "${BATS_DIR}/bats-core" ]; then
  echo "Installing BATS-core..."
  mkdir -p "${BATS_DIR}"
  git clone --depth 1 https://github.com/bats-core/bats-core.git "${BATS_DIR}/bats-core"
  git clone --depth 1 https://github.com/bats-core/bats-support.git "${BATS_DIR}/bats-support"
  git clone --depth 1 https://github.com/bats-core/bats-assert.git "${BATS_DIR}/bats-assert"
fi

BATS="${BATS_DIR}/bats-core/bin/bats"

# Step 2: Build and start Docker Compose services
echo "=== Building Docker images ==="
$COMPOSE_CMD build 2>&1
if [ $? -ne 0 ]; then
  echo "ERROR: Docker build failed"
  exit 1
fi

echo "=== Starting E2E test services ==="
$COMPOSE_CMD up -d 2>&1

echo "=== Waiting for services (up to 120s) ==="
$COMPOSE_CMD up -d --wait --wait-timeout 120 2>&1 || {
  echo "WARNING: --wait timed out, checking status manually..."
  $COMPOSE_CMD ps 2>&1
}

echo "=== Debug: Container status ==="
$COMPOSE_CMD ps 2>&1

echo "=== Debug: Testing backup container ==="
$COMPOSE_CMD exec -T backup bash -c '
  echo "Container is running"
  echo "--- Env vars ---"
  env | grep -E "RESTIC|PROVISION_MODE|TELEGRAM|POSTGRES" | sort
  echo "--- Test data ---"
  ls /test_data/ 2>&1 || echo "Test data NOT found"
  echo "--- Restic repo dir ---"
  ls -la /restic-repo/ 2>&1 || echo "Restic repo dir NOT found"
' 2>&1 || echo "WARNING: Could not exec into backup container"

# Step 3: Smoke test - init restic with local repo
echo "=== Smoke test: Restic init ==="
$COMPOSE_CMD exec -T backup bash -c '
  set -x
  export RESTIC_REPOSITORY="/restic-repo"
  restic cat config 2>/dev/null || restic init
  echo "Restic ready"
' 2>&1 || echo "WARNING: Smoke test failed with exit code $?"

# Step 4: Run BATS tests
echo "=== Running BATS tests ==="
"${BATS}" --print-output-on-failure --verbose-run --trace --timing "${E2E_DIR}"/test_*.bats 2>&1
TEST_EXIT=$?

echo "=== E2E tests finished with exit code: ${TEST_EXIT} ==="
exit $TEST_EXIT
