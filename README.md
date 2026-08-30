# Auto Mac spoofing and Hostname randomization for Linux, SteamOS and kicksecure

## What it does
This script performs:
- **Random MAC spoofing** (permanent until you remove it)
- **Random hostname generation**
- **Automatic randomization on every boot** (hostname + MAC)
- **Manual MAC spoofing** when needed
- Works for **Ethernet and Wi-Fi** adapters

If you use USB Wi‑Fi adapters, some of them may not accept MAC changes through the automatic method. In my tests, the script worked fully on **PCIe Wi‑Fi/Ethernet** cards, but for **USB Wi‑Fi**, you may need to apply the MAC manually using `ip link` commands.

## Important notes
- Requires **`nmcli` (NetworkManager)** and **`systemd-networkd (networkd)`**.
- For **Kicksecure**, run the script as **`sysmaint`**.

## Scripts included
- `mac-host-changer.sh`  
  Linux / kicksecure version.
- `mac-host-changer-s.sh`  
  SteamOS version (same logic), but it temporarily disables the SteamOS **read-only** protection so the changes persist, then re-enables it after finishing.

## SteamOS read-only behavior
On SteamOS, at the start of each relevant function the script disables the read-only service so configuration files can be written. At the end of the function it enables the read-only service again.

## Execution permissions
```bash
chmod +x mac-host-changer.sh mac-host-changer-s.sh
```

## How to run
### Linux (general) and kicksecure
```bash
./mac-host-changer.sh
```

### SteamOS
```bash
./mac-host-changer-s.sh
```

## What each menu option does
The script shows an interactive menu with the following options:

1) **Random Hostname Generator**  
   Generates a new random hostname (using a random prefix + 3-character suffix), then applies it by updating:
   - `/etc/hostname`
   - the `127.0.1.1` entry in `/etc/hosts`
   - the system hostname via `hostnamectl set-hostname`

2) **Manual Hostname Setter**  
   Prompts you for a hostname string and then applies it using the same mechanism as option (1):
   - `/etc/hostname`
   - `127.0.1.1` line in `/etc/hosts`
   - `hostnamectl set-hostname`

3) **Permanent MAC Spoof (manual)**  
   - Prompts for the target **interface name**
   - Prompts for the **MAC address** you want to set
   - Writes `/etc/systemd/network/10-mac-address.network` with:
     - `[Match] Name=<interface>`
     - `[Link] MACAddress=<mac>`
   - Enables and starts the relevant `systemd-networkd` configuration to make it persist across reboots

4) **Permanent MAC Spoof (random MAC)**  
   - Prompts for the target **interface name**
   - Generates a random MAC address
   - Writes `/etc/systemd/network/10-mac-address.network` using that generated MAC
   - Enables and starts the service so the MAC persists across reboots

5) **Permanent Random Hostname + Manual MAC Spoof**  
   Runs both actions in sequence:
   - Removes any previous MAC spoof configuration
   - Applies a **manual MAC spoof** (option 3 flow)
   - Generates and applies a **random hostname** (option 1 flow)

6) **Auto Random MAC Spoof and Random Hostname Each Boot**  
   Enables automatic randomization on every boot by:
   - Removing any existing permanent MAC spoof configuration
   - Creating a systemd oneshot service (`hostname-randomizer.service`) that runs at boot and sets a new randomized hostname
   - Writing the NetworkManager config `/etc/NetworkManager/conf.d/00-macrandomize.conf` to enable random MAC behavior for Wi‑Fi and Ethernet
   - Restarting NetworkManager so the new behavior becomes active immediately
    
  7) **Auto Random MAC Spoof Each Boot**  
   - Enables automatic mac randomization on every boot without host randomization!

8) **Disable auto and permanent mac spoofing**  
   Removes the files/services created for spoofing:
   - Deletes `/etc/systemd/network/10-mac-address.network` (persistent MAC spoof)
   - Removes the auto boot service `/etc/systemd/system/hostname-randomizer.service`
   - Removes NetworkManager configuration `/etc/NetworkManager/conf.d/00-macrandomize.conf`
   - Restarts NetworkManager networking to return to the normal MAC/hostname behavior

0) **Exit**  
   Closes the menu.

## Notes about USB Wi‑Fi
Some USB Wi‑Fi adapters may ignore automatic MAC changes. If that happens:
- apply the desired MAC manually using `ip link` for the target interface, then confirm with:
  - `ip link show <interface>`
  - or `nmcli device show <interface>`
  
## What files are modified
Depending on the option selected, the script modifies:
- `/etc/hostname`
- `/etc/hosts`
- `systemd-networkd` config: `/etc/systemd/network/10-mac-address.network`
- auto hostname service: `/etc/systemd/system/hostname-randomizer.service`
- NetworkManager config: `/etc/NetworkManager/conf.d/00-macrandomize.conf`
- SteamOS read-only state (SteamOS-only script)

## Troubleshooting
- If MAC spoof doesn’t change:
  - confirm the interface name (example: `eth0`, `enp3s0`, `wlan0`, etc.)
  - confirm `systemd-networkd` and NetworkManager are active
  - test with `ip link show <interface>`
- If hostname doesn’t update:
  - verify `/etc/hosts` contains a matching `127.0.1.1` line
  - verify `hostnamectl` is available

# Doe monero para nos ajudar: (donate XMR)
```bash
87JGuuwXzoMGwQAcSD7cvS7D7iacPpN2f5bVqETbUvCgdEmrPZa12gh5DSiKKRgdU7c5n5x1UvZLj8PQ7AAJSso5CQxgjak
```
 
### My homepage about cybersecurity and anonymity:

https://traderprofissional.com.br/seguranca-digital.aspx


