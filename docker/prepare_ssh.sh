#!/usr/bin/env bash
set -e

# Check if all arguments are provided
if [ -z "$TARGET_DOMAIN" ] || [ -z "$TARGET_DOMAIN_USER" ] || [ -z "$SSH_PRIVATE_KEY" ]; then
    echo "Error:  Variable: ${TARGET_DOMAIN} ${TARGET_DOMAIN_USER} ${SSH_PRIVATE_KEY} not defined"
    exit 1
fi

# make the host known
ssh-keyscan -t rsa $TARGET_DOMAIN > /etc/ssh/ssh_known_hosts

# Create the private key file
echo "$SSH_PRIVATE_KEY" > /private_key
chmod 600 /private_key

# Create the ssh_config file
cat <<EOL > /etc/ssh/ssh_config
Host storagebox
    Hostname $TARGET_DOMAIN
    User $TARGET_DOMAIN_USER
    IdentityFile /private_key
EOL
