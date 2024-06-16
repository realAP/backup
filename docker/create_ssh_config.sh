#!/bin/bash

# Check if all arguments are provided
if [ -z "$TARGET_DOMAIN" ] || [ -z "$TARGET_DOMAIN_USER" ] || [ -z "$NAME_OF_PRIVATE_KEY" ]; then
    echo "Usage: $0 <TARGET_DOMAIN> <TARGET_DOMAIN_USER> <NAME_OF_PRIVATE_KEY>"
    exit 1
fi

# Create the ssh_config file
cat <<EOL > /etc/ssh/ssh_config
Host storagebox
    Hostname $TARGET_DOMAIN
    User $TARGET_DOMAIN_USER
    IdentityFile /private_key
EOL