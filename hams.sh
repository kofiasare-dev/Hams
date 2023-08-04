#!/bin/bash

export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/${UID}/bus}"

HAMS_APP="achieve-api-staging"
HAMS_INTERVAL=1200 #seconds
HEROKU_ICON_PATH="/usr/share/icons/heroku/legacy.png"
UP_SOUND="/usr/share/sounds/freedesktop/stereo/service-login.oga"
DOWN_SOUND="/usr/share/sounds/freedesktop/stereo/service-logout.oga"
LOG_FILE="/home/kofiasare/Desktop/.hams/log/$HAMS_APP.log"


log() {
    local message=$1
    timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "$HAMS_APP | [$timestamp] - $message" >> $LOG_FILE
}

send_notification() {
    local sound=$1
    local title=$2
    local message=$3
    notify-send -i "$HEROKU_ICON_PATH" "Heroku ( "$title" )" "$message" && paplay "$sound"
}

restart_app() {
    log "Restarting Heroku app..."
    heroku ps:restart --app $HAMS_APP
    log "Heroku app restarted."
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
        log "Connection attempt $retries failed. Retrying in $backoff_time seconds..."
        sleep $backoff_time

        # Increase backoff time for the next retry (exponential backoff)
        backoff_time=$((backoff_time * 2))
    done

    return 1
}

check_app_status() {
    if ! check_internet_connection; then
        send_notification "$DOWN_SOUND" "$HAMS_APP" "❌ No internet connection! Check your internet connection"
        return
    fi

    response=$(heroku ps --app $HAMS_APP)
    if [[ $response == *"web.1: up"* ]]; then
        send_notification "$UP_SOUND" "$HAMS_APP" "✅ API is up and running!"
    else
        send_notification "$DOWN_SOUND" "$HAMS_APP" "❌ API is not responding! Trying to restart..."
        restart_app
    fi
}



# Infinite loop to check the status intermittently
while true; do
    log "Checking the status of the Heroku app.."
    check_app_status

    next_run=$(date -d "+$HAMS_INTERVAL seconds" +"%Y-%m-%d %H:%M:%S")
    log "Next run: $next_run"

    sleep $HAMS_INTERVAL
done
