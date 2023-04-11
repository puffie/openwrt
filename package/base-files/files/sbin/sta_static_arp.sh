#!/bin/sh

# Extract the MAC address and IP address from the arguments passed by hostapd_cli
interface="$1"
event="$2"
mac="$3"

# Log function
log() {
    echo "$(date) $1"
}

# Function to remove static ARP entry for a client
remove_static_arp_entry() {
    ip=$(arp -an | awk -v mac="${mac}" '$0 ~ mac { gsub(/[\(\)]/, "", $2); print $2}')
    if [ ! -z "${ip}" ]; then
        arp -d "${ip}"
        log "$(date) Static ARP entry removed for MAC address ${mac} with IP address ${ip}."
    fi
}

# Function to wait ARP entry and make it static
create_static_arp_entry() {
    # Wait for the client to be assigned an IP address
    timeout=30
    while [ $timeout -gt 0 ]; do
        ip=$(arp -an | awk -v mac="${mac}" '$0 ~ mac { gsub(/[\(\)]/, "", $2); print $2}')
        if [ ! -z "${ip}" ]; then
            # Set a static ARP entry for the MAC address and IP address
            arp -s "${ip}" "${mac}"
            log "Static ARP entry set for MAC address ${mac} with IP address ${ip}."
            exit 0
        fi
        sleep 1
        timeout=$((timeout-1))
    done
    log "Failed to set Static ARP entry for ${mac}."
}

log "Received ${event} event for client ${mac} on interface ${interface}."

case "$event" in
    AP-STA-CONNECTED)
        create_static_arp_entry &
        ;;
    AP-STA-DISCONNECTED)
        remove_static_arp_entry
        ;;
esac

exit 0

