#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
E2E_DIR="${SCRIPT_DIR}/e2e"
BATS_DIR="${E2E_DIR}/bats"

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

# Step 2: Generate SSH keys if not present
if [ ! -f "${E2E_DIR}/ssh/test_key" ]; then
  echo "Generating test SSH keys..."
  bash "${E2E_DIR}/ssh/generate_test_keys.sh"
fi

# Step 3: Start Docker Compose services
echo "Starting E2E test services..."
docker compose -p e2e -f "${E2E_DIR}/docker-compose.e2e.yaml" up -d --build --wait

# Step 4: Run tests, capture exit code
echo "Running BATS tests..."
set +e
"${BATS}" "${E2E_DIR}"/test_*.bats
TEST_EXIT=$?
set -e

# Step 5: Collect logs on failure
if [ $TEST_EXIT -ne 0 ]; then
  echo "=== Tests failed. Collecting logs... ==="
  mkdir -p "${E2E_DIR}/logs"
  docker compose -p e2e -f "${E2E_DIR}/docker-compose.e2e.yaml" logs > "${E2E_DIR}/logs/compose.log" 2>&1
fi

# Step 6: Tear down
echo "Tearing down E2E test services..."
docker compose -p e2e -f "${E2E_DIR}/docker-compose.e2e.yaml" down -v

echo "=== E2E tests finished with exit code: ${TEST_EXIT} ==="
exit $TEST_EXIT
