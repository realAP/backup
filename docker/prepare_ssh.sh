#!/usr/bin/env bash
set -e

source /bin/connection.sh

# make the host known
# on a flaky link the very first connection can already fail, so give it a few
# tries before the container gives up
keyscan_attempts=1
if [[ ${starlink_enabled} -eq 1 ]]; then
  keyscan_attempts=10
fi

for ((attempt = 1; attempt <= keyscan_attempts; attempt++)); do
  if ssh-keyscan -t rsa "$TARGET_DOMAIN" > /etc/ssh/ssh_known_hosts && [[ -s /etc/ssh/ssh_known_hosts ]]; then
    break
  fi
  echo "ssh-keyscan for $TARGET_DOMAIN failed (attempt ${attempt}/${keyscan_attempts})"
  if [[ ${attempt} -eq ${keyscan_attempts} ]]; then
    echo "Error: host key of '$TARGET_DOMAIN' could not be fetched."
    exit 1
  fi
  sleep 15
done

# Create the private key file
echo "$SSH_PRIVATE_KEY_BASE64" | base64 --decode > /private_key
chmod 600 /private_key

# Create the ssh_config file
cat <<EOL > /etc/ssh/ssh_config
Host storagebox
    Hostname $TARGET_DOMAIN
    User $TARGET_DOMAIN_USER
    IdentityFile /private_key
EOL

# restic spawns ssh itself for the sftp backend, so the keep alive settings for
# a satellite link belong into the ssh config
if [[ ${starlink_enabled} -eq 1 ]]; then
  cat <<EOL >> /etc/ssh/ssh_config
    # a satellite handover freezes the stream for a few seconds and the public
    # ip changes regularly - survive short outages instead of killing the
    # running transfer (15s * 8 = ~2min tolerance)
    ServerAliveInterval 15
    ServerAliveCountMax 8
    TCPKeepAlive yes
    ConnectTimeout 30
    ConnectionAttempts 5
    IPQoS throughput
EOL
fi
