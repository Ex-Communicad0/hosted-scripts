#!/bin/bash
# Lidarr .NET Core Migration Script

app=lidarr

if [[ ! -d $HOME/.logs ]]; then
    mkdir -p $HOME/.logs
fi

touch "$HOME/.logs/$app.log"
log="$HOME/.logs/$app.log"

function _upgrade() {
    echo "Stopping old install"

    sudo box disable lidarr
    sudo box stop lidarr
    # Download App
    echo "Downloading Lidarr"
    
    mkdir -p "$HOME/.tmp/"

    curl -sL "http://lidarr.servarr.com/v1/update/master/updatefile?os=linux&runtime=netcore&arch=x64" -o "$HOME/.tmp/lidarr.tar.gz" >> "$log" 2>&1 || {
        echo "Download failed."
        exit 1
    }

    # Extract
    echo "Extracting Lidarr"
    tar xfv "$HOME/.tmp/lidarr.tar.gz" --directory $HOME/ >> "$log" 2>&1 || {
        echo_error "Failed to extract"
        exit 1
    }
    rm -rf "$HOME/.tmp/lidarr.tar.gz"

    if [[ ! -d $HOME/.config/systemd/user/ ]]; then
        mkdir -p $HOME/.config/systemd/user/
    fi

    # Service File
    echo "Writing service file"
    cat > "$HOME/.config/systemd/user/lidarr.service" << EOF
[Unit]
Description=Lidarr Daemon
After=syslog.target network.target
[Service]
Type=simple
Environment="TMPDIR=$HOME/.tmp"
EnvironmentFile=$HOME/.install/.lidarr.lock
ExecStart=$HOME/Lidarr/Lidarr -nobrowser -data=$HOME/.config/Lidarr/
TimeoutStopSec=20
KillMode=process
Restart=on-failure
[Install]
WantedBy=multi-user.target
EOF

    # Enable/Start Prowlarr
    echo "Starting Lidarr"
    systemctl enable --now --user lidarr
    
}

echo "Welcome to Lidarr .NET Core Migration Script..."
echo ""
echo "What do you like to do?"
echo "Logs are stored at ${log}"
echo "upgrade = Upgrade Lidarr"
echo "exit = Exits Installer"
while true; do
    read -r -p "Enter it here: " choice
    case $choice in
        "install")
            _upgrade
            break
            ;;
        "exit")
            break
            ;;
        *)
            echo "Unknown Option."
            ;;
    esac
done
exit
