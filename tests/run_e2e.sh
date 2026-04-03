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

# Debug: show generated files
echo "=== Debug: SSH key files ==="
ls -la "${E2E_DIR}/ssh/"
echo "=== Debug: test_key_base64 content length ==="
wc -c "${E2E_DIR}/ssh/test_key_base64"

# Step 3: Build and start Docker Compose services
echo "=== Building Docker images ==="
docker compose -p e2e -f "${E2E_DIR}/docker-compose.e2e.yaml" build 2>&1
echo "=== Starting E2E test services ==="
docker compose -p e2e -f "${E2E_DIR}/docker-compose.e2e.yaml" up -d 2>&1

# Step 4: Wait for services and show debug info
echo "=== Waiting for services to be healthy ==="
for i in $(seq 1 60); do
  echo "--- Attempt $i ---"
  docker compose -p e2e -f "${E2E_DIR}/docker-compose.e2e.yaml" ps 2>&1
  # Check if all services are healthy/running
  UNHEALTHY=$(docker compose -p e2e -f "${E2E_DIR}/docker-compose.e2e.yaml" ps --format json 2>/dev/null | grep -v '"healthy"' | grep -c '"Health"' || true)
  if [ "$UNHEALTHY" = "0" ]; then
    echo "All services healthy!"
    break
  fi
  if [ "$i" = "60" ]; then
    echo "=== TIMEOUT: Services not healthy after 60 attempts ==="
    echo "=== Container logs ==="
    docker compose -p e2e -f "${E2E_DIR}/docker-compose.e2e.yaml" logs 2>&1
    exit 1
  fi
  sleep 3
done

# Debug: show container status
echo "=== Debug: Final container status ==="
docker compose -p e2e -f "${E2E_DIR}/docker-compose.e2e.yaml" ps 2>&1

# Debug: verify backup container can reach other services
echo "=== Debug: Testing backup container connectivity ==="
docker compose -p e2e -f "${E2E_DIR}/docker-compose.e2e.yaml" exec -T backup bash -c 'echo "Container is running"; ls /run/secrets/ssh_key_base64 && echo "SSH key file exists"; cat /run/secrets/ssh_key_base64 | wc -c; echo "Env vars:"; env | grep -E "TARGET_DOMAIN|RESTIC|PROVISION_MODE|TELEGRAM|POSTGRES" | sort' 2>&1 || echo "WARNING: Could not exec into backup container"

# Step 5: Smoke test - verify core functionality before BATS
echo "=== Smoke test: init SSH and restic ==="
docker compose -p e2e -f "${E2E_DIR}/docker-compose.e2e.yaml" exec -T backup bash -c '
  export SSH_PRIVATE_KEY_BASE64=$(cat /run/secrets/ssh_key_base64)
  export RESTIC_REPOSITORY="sftp:storagebox:${RESTIC_REPOSITORY_NAME}"
  echo "=== Running prepare_ssh.sh ==="
  prepare_ssh.sh
  echo "=== SSH setup done ==="
  echo "=== Testing SFTP connection ==="
  ssh -o StrictHostKeyChecking=accept-new storagebox ls / || echo "SFTP connection test result: $?"
  echo "=== Initializing restic repo ==="
  restic init || restic cat config || echo "Restic init/config result: $?"
  echo "=== Smoke test complete ==="
' 2>&1 || echo "WARNING: Smoke test failed with exit code $?"

# Step 6: Run tests with verbose output, capture exit code
echo "=== Running BATS tests ==="
set +e
"${BATS}" --print-output-on-failure --verbose-run --trace --timing "${E2E_DIR}"/test_*.bats 2>&1
TEST_EXIT=$?
set -e

# Step 7: Collect logs
echo "=== Collecting container logs ==="
mkdir -p "${E2E_DIR}/logs"
docker compose -p e2e -f "${E2E_DIR}/docker-compose.e2e.yaml" logs > "${E2E_DIR}/logs/compose.log" 2>&1
# Show logs in CI output too
docker compose -p e2e -f "${E2E_DIR}/docker-compose.e2e.yaml" logs 2>&1

# Step 8: Tear down
echo "=== Tearing down E2E test services ==="
docker compose -p e2e -f "${E2E_DIR}/docker-compose.e2e.yaml" down -v

echo "=== E2E tests finished with exit code: ${TEST_EXIT} ==="
exit $TEST_EXIT
