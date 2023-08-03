#!/bin/bash

export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/${UID}/bus}"

APP_NAME="achieve-api-staging"
CHECK_INTERVAL=1800 #seconds
HEROKU_ICON_PATH="/usr/share/icons/heroku/legacy.png"
UP_SOUND="/usr/share/sounds/freedesktop/stereo/service-login.oga"
DOWN_SOUND="/usr/share/sounds/freedesktop/stereo/service-logout.oga"
LOG_FILE="/home/kofiasare/Desktop/.heroku_app_checker/log/$APP_NAME.log" # Set the desired log file path


send_notification() {
    local sound=$1
    local title=$2
    local message=$3
    notify-send -i "$HEROKU_ICON_PATH" "Heroku ( "$title" )" "$message" && paplay "$sound"
}

restart_app() {
    echo "Restarting Heroku app..."
    heroku restart --app $APP_NAME
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] - Heroku app restarted." >> "$LOG_FILE"
}

check_internet_connection() {
    local max_retries=3
    local retries=0
    local backoff_time=30 #seconds


    while [[ $retries -lt $max_retries ]]; do
        if ping -c 1 8.8.8.8 &> /dev/null; then
            return 0
        fi

        retries=$((retries + 1))
        echo "Connection attempt $retries failed. Retrying in $backoff_time seconds..." >> $LOG_FILE
        sleep $backoff_time

        # Increase backoff time for the next retry (exponential backoff)
        backoff_time=$((backoff_time * 2))
    done

    return 1
}

check_app_status() {
    if ! check_internet_connection; then
        send_notification "$DOWN_SOUND" "$APP_NAME" "❌ No internet connection! Check your internet connection"
        return
    fi

    response=$(heroku ps --app $APP_NAME)
    if [[ $response == *"web.1: up"* ]]; then
        send_notification "$UP_SOUND" "$APP_NAME" "✅ API is up and running!"
    else
        send_notification "$DOWN_SOUND" "$APP_NAME" "❌ API is not responding! Trying to restart..."
        restart_app
    fi
}

# Infinite loop to check the status intermittently
while true; do
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] - Checking the status of the Heroku app..." >> $LOG_FILE
    check_app_status
    next_run=$(date -d "+$CHECK_INTERVAL seconds" +"%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] - Next run: $next_run" >> $LOG_FILE
    sleep $CHECK_INTERVAL
done
