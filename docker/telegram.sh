#!/usr/bin/env bash

# Replace with your bot token and chat ID
BOT_TOKEN=${TELEGRAM_TOKEN}
CHAT_ID=${TELEGRAM_CHAT_ID}

# Check if the file path or message is provided as the first argument
if [ -z "$1" ]; then
    echo "Usage: $0 path/to/your/logfile.log | message to send"
    exit 1
fi

IS_MESSAGE_OR_FILE_PATH="$1"

# Check if the input is a file or a message
if [ -f "$IS_MESSAGE_OR_FILE_PATH" ]; then
    LOG_CONTENT=$(cat "$IS_MESSAGE_OR_FILE_PATH")
else
    LOG_CONTENT="${IS_MESSAGE_OR_FILE_PATH}"
fi

# Define the endpoint
URL="https://api.telegram.org/bot${BOT_TOKEN}/sendMessage"

# Telegram has a limit of 4096 characters per message
MAX_LENGTH=4096

send_message() {
    local message=$1
    curl -o /dev/null -s -X POST $URL -d chat_id=$CHAT_ID -d text="$message"
}

# Send the message in chunks if it exceeds MAX_LENGTH
if [ ${#LOG_CONTENT} -le $MAX_LENGTH ]; then
    send_message "${LOG_CONTENT}"
else
    echo "Log content is too large, splitting into multiple messages"
    start=0
    while [ $start -lt ${#LOG_CONTENT} ]; do
        chunk="${LOG_CONTENT:start:MAX_LENGTH}"
        send_message "${chunk}"
        start=$(($start + $MAX_LENGTH))
        sleep 1  # To avoid hitting Telegram's rate limits
    done
fi
