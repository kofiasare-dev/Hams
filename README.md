# Hams

The **Hams** is a Bash script designed to check the status of a Heroku app, restart it if necessary, and send notifications based on its status. The script runs as a service using systemd and continuously monitors the specified Heroku app at regular intervals.

Once the script is running as a service, it will continuously monitor the specified Heroku app at the defined intervals. If the app is up and running, it will show a desktop notification with the Heroku icon and play the "app up" sound. If the app is not responding, it will attempt to restart the app and notify you accordingly.

Check the log file (if specified) for detailed information about the script's activities and any issues encountered.

## Features

- Checks the status of a Heroku app and sends notifications.
- Supports automatic app restart if the app is not responding.
- Implements exponential backoff for retrying internet connection checks.
- Uses systemd to run the script as a service.

## Requirements

- Bash shell
- Heroku CLI (Command Line Interface) installed and configured with the appropriate credentials.
- `paplay` for playing notification sounds.
- `notify-send` for displaying desktop notifications.

## Getting Started

1. Clone the repository or copy the script to your preferred directory.

2. Make sure you have all the required dependencies installed.

3. Set the necessary environment variables:

   - `HAMS_APP`: The name of the Heroku app you want to monitor.
   - `CHECK_INTERVAL`: The time interval (in seconds) between consecutive checks.
   - `HEROKU_ICON_PATH`: Path to the Heroku icon for notifications.
   - `UP_SOUND`: Path to the sound file for the "app up" notification.
   - `DOWN_SOUND`: Path to the sound file for the "app down" notification.
   - `HEROKU_ICON_PATH`: Path to the heroku icon

4. Optionally, modify the log file path in the script to point to your desired location:

   ```bash
   LOG_FILE="/path/to/your/logfile.log"

   chmod +x hams.sh

   ./hams.sh

   ```

   Optionally, you can configure systemd to run the script as a service. Here's a sample service unit file named hams.service. Customize the paths accordingly:

   ```ini
   [Unit]
   Description=Heroku application management service
   After=network.target

   [Service]
   User=<your-username>
   Environment="PULSE_SERVER=unix:/run/user/1000/pulse/native"
   ExecStart=<absolute-path-to-hams.sh>
   WorkingDirectory=<absolute-path-hams-directory>
   Restart=on-failure

   [Install]
   WantedBy=multi-user.target

   ```

   Load and enable the service:

   ```bash
    sudo systemctl daemon-reload
    sudo systemctl start heroku
    sudo systemctl enable heroku
   ```
