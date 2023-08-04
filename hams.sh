#!/bin/bash

export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=/run/user/${UID}/bus}"

# Configurations
HAMS_APP="${HAMS_APP:-achieve-api-staging}"
HAMS_INTERVAL="${HAMS_INTERVAL:-1200}" # seconds
HEROKU_ICON_PATH="/usr/share/icons/heroku/legacy.png"
UP_SOUND="/usr/share/sounds/freedesktop/stereo/service-login.oga"
DOWN_SOUND="/usr/share/sounds/freedesktop/stereo/service-logout.oga"
LOG_FILE="/home/kofiasare/Desktop/.hams/log/$HAMS_APP.log"


log() {
    local app=$1
    local message=$2
    echo "$app | [$(date +"%Y-%m-%d %H:%M:%S")] - $message" >> $LOG_FILE
}

notify_with_log() {
    local app=$1
    local sound=$2
    local message=$3

    notify-send -i "$HEROKU_ICON_PATH" "Heroku ( $app )" "$message" && paplay "$sound"
    log "$app" "$message"
}

restart_app() {
    local app=$1

    log "Restarting Heroku app..."
    heroku ps:restart --app $app
    log "Heroku app restarted."
}

can_connect_to() {
    local app=$1
    local max_retries=3
    local retries=0
    local backoff_time=30 #seconds

    while [[ $retries -lt $max_retries ]]; do
        if ping -c 1 8.8.8.8 &> /dev/null; then
            return 0
        fi

        retries=$((retries + 1))
        log "$app" "Connection attempt $retries failed. Retrying in $backoff_time seconds..."
        sleep $backoff_time

        # Increase backoff time for the next retry (exponential backoff)
        backoff_time=$((backoff_time * 2))
    done

    return 1
}

check_app_state() {
    local app=$1

    if can_connect_to "$app"; then
        if heroku ps --app "$app" | grep -q "web.1: up"; then
            return 0
        else
            return 1
        fi
    else
        return 2
    fi
}

# Infinite loop to check the status intermittently
while true; do
    log "$HAMS_APP" "Checking the status of the Heroku app..."
    check_app_state "$HAMS_APP"

    case $? in
        0)
            notify_with_log "$HAMS_APP" "$UP_SOUND"  "✅ API is up and running!"
            ;;
        1)
            notify_with_log "$HAMS_APP" "$DOWN_SOUND" "❌ API is not responding! Trying to restart..."
            restart_app $HAMS_APP
            ;;
        2)
            notify_with_log  "$HAMS_APP" "$DOWN_SOUND" "❌ No internet connection! Check your internet connection"
            ;;

    esac

    next_run=$(date -d "+$HAMS_INTERVAL seconds" +"%Y-%m-%d %H:%M:%S")
    log "$HAMS_APP" "Next run: $next_run"

    sleep $HAMS_INTERVAL
done
