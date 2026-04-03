#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Generating ephemeral SSH keypair for E2E tests..."

if command -v ssh-keygen &>/dev/null; then
  ssh-keygen -t rsa -b 2048 -f "${SCRIPT_DIR}/test_key" -N "" -q
else
  # Fallback: use Python cryptography to generate OpenSSH-format keys
  python3 -c "
from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import rsa
import os

key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
private_pem = key.private_bytes(serialization.Encoding.PEM, serialization.PrivateFormat.OpenSSH, serialization.NoEncryption())
public_ssh = key.public_key().public_bytes(serialization.Encoding.OpenSSH, serialization.PublicFormat.OpenSSH)

script_dir = '${SCRIPT_DIR}'
with open(os.path.join(script_dir, 'test_key'), 'wb') as f:
    f.write(private_pem)
with open(os.path.join(script_dir, 'test_key.pub'), 'wb') as f:
    f.write(public_ssh)
os.chmod(os.path.join(script_dir, 'test_key'), 0o600)
"
fi

# Base64-encode the private key (single line) for the backup container
base64 -w 0 "${SCRIPT_DIR}/test_key" > "${SCRIPT_DIR}/test_key_base64"
echo "SSH keypair generated at ${SCRIPT_DIR}/test_key"
