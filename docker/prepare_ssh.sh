#!/usr/bin/env bash
set -e

# make the host known
ssh-keyscan -t rsa $TARGET_DOMAIN > /etc/ssh/ssh_known_hosts

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
