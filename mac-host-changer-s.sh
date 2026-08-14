#!/bin/bash

#check root privileges
check_root(){
# Check if user is root
if [[ $EUID -ne 0 ]]; then
    echo "Error: This function requires 'root' privileges."
    exit 1
fi
}
check_root

#check dependencies
check_deps() { echo "[*] Checking dependencies..."
if ! command -v nmcli >/dev/null 2>&1; then
    echo "❌ nmcli not found. Install NetworkManager..."
    echo "sudo apt update && sudo apt install -y network-manager"
sleep 3
fi

if ! command -v ip >/dev/null 2>&1; then
    echo "❌ ip command not found!"
    echo "   Install with: sudo apt install iproute2"
sleep 3
    exit 1
fi
}
check_deps

random-hostname()
{
# =========================================
# Random Hostname Generator for linux
# =========================================

sudo steamos-readonly disable
USED_HOSTNAMES_FILE="/tmp/used_hostnames.txt"
touch "$USED_HOSTNAMES_FILE" 2>/dev/null

# -----------------------------------------
# Function: Generate random character
# -----------------------------------------
rand_char() {
    CHARS="$1"
    LEN=$(printf '%s' "$CHARS" | wc -c)
    [ "$LEN" -eq 0 ] && LEN=1
    POS=$((RANDOM % LEN))
    printf '%s' "$CHARS" | cut -c$((POS + 1))
}

# -----------------------------------------
# Function: Generate Unique Hostname
# Format: prefix-XXX (e.g., device-aB3, gw-pIZ)
# -----------------------------------------
generate_unique_hostname() {
    # Pick random prefix
    SELECT=$(( (RANDOM % 4) + 1 ))
    case $SELECT in
        1) PREFIX="device-" ;;
        2) PREFIX="my-dev-" ;;
        3) PREFIX="rt-" ;;
        4) PREFIX="gw-" ;;
    esac
    
    # Generate 3-char suffix
    SUFFIX=""
    i=1
    while [ $i -le 3 ]; do
        CASE=$(( RANDOM % 3 ))
        case $CASE in
            0) CHAR=$(rand_char "abcdefghijklmnopqrstuvwxyz") ;;
            1) CHAR=$(rand_char "ABCDEFGHIJKLMNOPQRSTUVWXYZ") ;;
            2) CHAR=$(rand_char "0123456789") ;;
        esac
        SUFFIX="${SUFFIX}${CHAR}"
        i=$((i + 1))
    done
    
    ANON_HOSTNAME="${PREFIX}${SUFFIX}"
    
    # Check uniqueness (max 50 attempts)
    ATTEMPT=0
    while grep -qxF "$ANON_HOSTNAME" "$USED_HOSTNAMES_FILE" 2>/dev/null; do
        SUFFIX=""
        i=1
        while [ $i -le 3 ]; do
            CASE=$(( RANDOM % 3 ))
            case $CASE in
                0) CHAR=$(rand_char "abcdefghijklmnopqrstuvwxyz") ;;
                1) CHAR=$(rand_char "ABCDEFGHIJKLMNOPQRSTUVWXYZ") ;;
                2) CHAR=$(rand_char "0123456789") ;;
            esac
            SUFFIX="${SUFFIX}${CHAR}"
            i=$((i + 1))
        done
        ANON_HOSTNAME="${PREFIX}${SUFFIX}"
        ATTEMPT=$((ATTEMPT + 1))
        [ $ATTEMPT -gt 50 ] && break
    done
    
    echo "$ANON_HOSTNAME" >> "$USED_HOSTNAMES_FILE" 2>/dev/null
}

# ==========================================
# MAIN EXECUTION FOR DEBIAN
# ==========================================

echo "[*] Generating new random hostname..."
generate_unique_hostname

OLD_HOSTNAME=$(hostname)
NEW_HOSTNAME="$ANON_HOSTNAME"

echo "[+] New hostname generated: $NEW_HOSTNAME"

# -----------------------------------------
# 1. Edit /etc/hostname
# -----------------------------------------
echo "[*] Updating /etc/hostname..."
echo "$NEW_HOSTNAME" | sudo tee /etc/hostname > /dev/null

# -----------------------------------------
# 2. Edit /etc/hosts (only 127.0.1.1 line)
# -----------------------------------------
echo "[*] Updating /etc/hosts..."
sudo sed -i "s/^127\.0\.1\.1\s*$OLD_HOSTNAME/127.0.1.1\t$NEW_HOSTNAME/" /etc/hosts

# -----------------------------------------
# 3. Apply hostname via hostnamectl
# -----------------------------------------
echo "[*] Applying new configuration..."
sudo hostnamectl set-hostname "$NEW_HOSTNAME"

# -----------------------------------------
# 4. Final verification
# -----------------------------------------
sleep 1
echo ""
echo "==================================="
echo "✅ Configuration completed!"
echo "==================================="
echo "Old hostname: $OLD_HOSTNAME"
echo "New hostname: $(hostname)"
echo ""
echo "/etc/hostname:"
cat /etc/hostname
echo ""
echo "/etc/hosts (relevant line):"
grep "127\.0\." /etc/hosts
echo ""
echo "Username (UNCHANGED): $USER"
echo "==================================="


systemctl restart NetworkManager
nmcli networking off
nmcli networking on
sudo steamos-readonly enable
echo
}


#manual false vendor mac spoofing
mac-spoof-steamos()
{
sudo steamos-readonly disable
echo "MacSpoof permanent with manual mac"
nmcli connection show
read -rp "Enter the interface name: "  interface
read -rp "Enter the false vendor mac (https://github.com/leandroibov/gerador-de-enderecos-mac): " mac
sudo cat > /etc/systemd/network/10-mac-address.network << 'EOF'
[Match]
Name=$interface

[Link]
MACAddress=$mac

[Network]
DHCP=yes
EOF
sudo sed -i "s|\$interface|$interface|g; s|\$mac|$mac|g" /etc/systemd/network/10-mac-address.network
sudo chmod +x /etc/systemd/network/10-mac-address.network
echo "Enable and start service to permanent mac spoof on boot!"
sudo systemctl enable systemd-networkd
sudo systemctl start systemd-networkd
sudo systemctl restart systemd-networkd
echo ""
echo "Permanent Mac Spoof is configured in /etc/systemd/network/10-mac-address.network"
cat /etc/systemd/network/10-mac-address.network
sudo steamos-readonly enable
echo
}

# =========================================
# MANUAL HOSTNAME FUNCTION
# =========================================

manual-hostname()
{
echo "==================================="
echo "Manual Hostname Setter"
echo "==================================="
echo ""
sudo steamos-readonly disable
read -rp "Enter your desired hostname: " NEW_HOSTNAME

# Validate hostname (basic check)
if [ -z "$NEW_HOSTNAME" ]; then
    echo "❌ Error: Hostname cannot be empty!"
    
    sleep 2
    return 1
fi

OLD_HOSTNAME=$(hostname)

echo "[*] Updating /etc/hostname..."
echo "$NEW_HOSTNAME" | sudo tee /etc/hostname > /dev/null

echo "[*] Updating /etc/hosts..."
sudo sed -i "s/^127\.0\.1\.1\s*$OLD_HOSTNAME/127.0.1.1\t$NEW_HOSTNAME/" /etc/hosts

echo "[*] Applying new configuration..."
sudo hostnamectl set-hostname "$NEW_HOSTNAME"

echo "[*] Restarting network services..."
systemctl restart NetworkManager
nmcli networking off
nmcli networking on



echo ""
echo "==================================="
echo "✅ Manual hostname completed!"
echo "==================================="
echo "Old hostname: $OLD_HOSTNAME"
echo "New hostname: $(hostname)"
echo "Username (UNCHANGED): $USER"
echo "==================================="
sudo steamos-readonly enable
echo ""
}



# =========================================
# MANUAL MAC SPOOF RANDOM + HOSTNAME RANDOM
# =========================================

mac-spoof-random-all()
{
    echo "==================================="
    echo "Manual MAC Spoof + Random Hostname"
    echo "==================================="
    echo ""
sudo steamos-readonly disable
remove-mac-spoof
    echo ""
    echo "[*] Running MAC spoof generator..."
    mac-spoof-steamos
    
    echo "[*] Running random hostname generator..."
    random-hostname
   
    
    echo ""
    echo "==================================="
    echo "✅ Both configurations completed!"
    echo "==================================="
sudo steamos-readonly enable
    echo ""
}

mac-spoof-random-all-2()
{
    echo "========================================"
    echo "Auto Random MAC Spoof + Random Hostname"
    echo "========================================"
    echo ""
remove-mac-spoof
sudo steamos-readonly disable
    echo ""
    echo "[*] Running Random MAC spoof generator..."
    random-mac
    
    echo "[*] Running random hostname generator..."
    random-hostname
   
    
    echo ""
    echo "==================================="
    echo "✅ Both configurations completed!"
    echo "==================================="
sudo steamos-readonly enable
    echo ""
}

random-mac()
{
remove-mac-spoof
echo "MacSpoof permanent with random macs"
nmcli connection show
read -rp "Enter the interface name: "  interface

# Generate a random MAC address
mac=$(openssl rand -hex 6 | sed 's/\(..\)/\1:/g; s/.$//')
echo "Random mac generated: $mac"
 
sudo cat > /etc/systemd/network/10-mac-address.network << 'EOF'
[Match]
Name=$interface

[Link]
MACAddress=$mac

[Network]
DHCP=yes
EOF
sudo sed -i "s|\$interface|$interface|g; s|\$mac|$mac|g" /etc/systemd/network/10-mac-address.network
sudo chmod +x /etc/systemd/network/10-mac-address.network
echo "Enable and start service to permanent mac spoof on boot!"
sudo systemctl enable systemd-networkd
sudo systemctl start systemd-networkd
sudo systemctl restart systemd-networkd
nmcli networking off
nmcli networking on

echo ""
echo "Permanent Mac Spoof is configured in /etc/systemd/network/10-mac-address.network with random mac"
cat /etc/systemd/network/10-mac-address.network
echo
}

remove-mac-spoof()
{
sudo steamos-readonly disable
if [ -f /etc/systemd/network/10-mac-address.network ]; 
then 
echo "Removing /etc/systemd/network/10-mac-address.network"
rm -f /etc/systemd/network/10-mac-address.network; 
fi

echo "Removing service files"
rm -rf /etc/systemd/system/hostname-randomizer.service
rm -rf /etc/NetworkManager/conf.d/00-macrandomize.conf
echo "Restart networkd and nmcli..."
sudo systemctl enable NetworkManager
nmcli networking off
nmcli networking on
sudo steamos-readonly enable
echo "Done!"
echo
}

auto_spoofing() {
sudo steamos-readonly disable
remove-mac-spoof
echo "Creating Hostname Randomization Hooking before shutdown/poweroff/halt"
sudo cat > /etc/systemd/system/hostname-randomizer.service << 'EOF'
[Unit]
Description=Random Hostname Generator Service
After=local-fs.target
Before=network-online.target
DefaultDependencies=no

[Service]
Type=oneshot
ExecStart=/usr/local/bin/hostname-changer.sh
RemainAfterExit=no
StandardOutput=journal
StandardError=journal
User=root

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl enable hostname-randomizer.service
systemctl start hostname-randomizer.service


# Generate a random MAC address
sudo cat > /etc/NetworkManager/conf.d/00-macrandomize.conf << 'INNEROFF'
[device]
wifi.scan-rand-mac-address=yes

[connection]
wifi.cloned-mac-address=random
ethernet.cloned-mac-address=random
connection.stable-id=${CONNECTION}/${BOOT}
INNEROFF

#restart network manager
echo "Restart Network Manager"
systemctl restart NetworkManager

sudo cat > /usr/local/bin/hostname-changer.sh << 'EOF'
#!/bin/bash
# =============================================
# Random Hostname and Mac Generator for linux
# =============================================

USED_HOSTNAMES_FILE="/tmp/used_hostnames.txt"
touch "$USED_HOSTNAMES_FILE" 2>/dev/null

# -----------------------------------------
# Function: Generate random character
# -----------------------------------------
rand_char() {
    CHARS="$1"
    LEN=$(printf '%s' "$CHARS" | wc -c)
    [ "$LEN" -eq 0 ] && LEN=1
    POS=$((RANDOM % LEN))
    printf '%s' "$CHARS" | cut -c$((POS + 1))
}

# -----------------------------------------
# Function: Generate Unique Hostname
# Format: prefix-XXX (e.g., device-aB3, gw-pIZ)
# -----------------------------------------
generate_unique_hostname() {
    # Pick random prefix
    SELECT=$(( (RANDOM % 4) + 1 ))
    case $SELECT in
        1) PREFIX="device-" ;;
        2) PREFIX="my-dev-" ;;
        3) PREFIX="rt-" ;;
        4) PREFIX="gw-" ;;
    esac
    
    # Generate 3-char suffix
    SUFFIX=""
    i=1
    while [ $i -le 3 ]; do
        CASE=$(( RANDOM % 3 ))
        case $CASE in
            0) CHAR=$(rand_char "abcdefghijklmnopqrstuvwxyz") ;;
            1) CHAR=$(rand_char "ABCDEFGHIJKLMNOPQRSTUVWXYZ") ;;
            2) CHAR=$(rand_char "0123456789") ;;
        esac
        SUFFIX="${SUFFIX}${CHAR}"
        i=$((i + 1))
    done
    
    ANON_HOSTNAME="${PREFIX}${SUFFIX}"
    
    # Check uniqueness (max 50 attempts)
    ATTEMPT=0
    while grep -qxF "$ANON_HOSTNAME" "$USED_HOSTNAMES_FILE" 2>/dev/null; do
        SUFFIX=""
        i=1
        while [ $i -le 3 ]; do
            CASE=$(( RANDOM % 3 ))
            case $CASE in
                0) CHAR=$(rand_char "abcdefghijklmnopqrstuvwxyz") ;;
                1) CHAR=$(rand_char "ABCDEFGHIJKLMNOPQRSTUVWXYZ") ;;
                2) CHAR=$(rand_char "0123456789") ;;
            esac
            SUFFIX="${SUFFIX}${CHAR}"
            i=$((i + 1))
        done
        ANON_HOSTNAME="${PREFIX}${SUFFIX}"
        ATTEMPT=$((ATTEMPT + 1))
        [ $ATTEMPT -gt 50 ] && break
    done
    
    echo "$ANON_HOSTNAME" >> "$USED_HOSTNAMES_FILE" 2>/dev/null
}

# ==========================================
# MAIN EXECUTION FOR DEBIAN
# ==========================================

echo "[*] Generating new random hostname..."
generate_unique_hostname

OLD_HOSTNAME=$(hostname)
NEW_HOSTNAME="$ANON_HOSTNAME"

echo "[+] New hostname generated: $NEW_HOSTNAME"

# -----------------------------------------
# 1. Edit /etc/hostname
# -----------------------------------------
echo "[*] Updating /etc/hostname..."
echo "$NEW_HOSTNAME" | sudo tee /etc/hostname > /dev/null

# -----------------------------------------
# 2. Edit /etc/hosts (only 127.0.1.1 line)
# -----------------------------------------
echo "[*] Updating /etc/hosts..."
sudo sed -i "s/^127\.0\.1\.1\s*$OLD_HOSTNAME/127.0.1.1\t$NEW_HOSTNAME/" /etc/hosts

# -----------------------------------------
# 3. Apply hostname via hostnamectl
# -----------------------------------------
echo "[*] Applying new configuration..."
sudo hostnamectl set-hostname "$NEW_HOSTNAME"

# -----------------------------------------
# 4. Final verification
# -----------------------------------------
sleep 1
echo ""
echo "==================================="
echo "✅ Configuration completed!"
echo "==================================="
echo "Old hostname: $OLD_HOSTNAME"
echo "New hostname: $(hostname)"
echo ""
echo "/etc/hostname:"
cat /etc/hostname
echo ""
echo "/etc/hosts (relevant line):"
grep "127\.0\." /etc/hosts
echo ""
echo "Username (UNCHANGED): $USER"
echo "==================================="
EOF
chmod +x /usr/local/bin/hostname-changer.sh
echo "Auto mac spoofing and hostname randomization each boot activated!"
sudo steamos-readonly enable
}

# =========================================

# MAIN MENU
# =========================================
show-menu()
{
    while true; do
        clear
        echo "========================================================"
        echo "   SteamOS Wifi and Ethernet MAC AND HOSTNAME CHANGER"
        echo "========================================================"
        echo ""
        echo "  1) Random Hostname Generator"
        echo "  2) Manual Hostname Setter"
        echo "  3) Permanent MAC Spoof (manual)"
        echo "  4) Permanent MAC Spoof (random mac)"
        echo "  5) Permanent Random Hostname + Manual MAC Spoof"
        echo "  6) Auto Random MAC Spoof and Random Hostname Each Boot"
        echo "  7) Disable auto and permanent mac spoofing"
        echo "  0) Exit"
        echo ""
        echo "=============================================="
        echo ""
        read -rp "Select an option [0-7]: " OPTION

        case $OPTION in
            1) random-hostname ;;
            2) manual-hostname ;;
            3) mac-spoof-steamos ;;
            4) random-mac ;;
            5) mac-spoof-random-all ;;
            6) auto_spoofing ;;
            7) remove-mac-spoof ;;
            0) echo "Exiting..."; sleep 2; exit 0 ;;
            *) echo "❌ Invalid option! Please choose 0-7."; sleep 2 ;;
        esac
    done
}

show-menu
exit 0


















