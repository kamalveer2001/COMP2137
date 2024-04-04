#!/bin/bash

# Function to log changes
log_changes() {
    local message="$1"
    if [ "$VERBOSE" = true ]; then
        echo "$message"
    fi
    logger "$message"
}

# Function to update hostname
update_hostname() {
    local desired_name="$1"
    local current_name=$(hostname)
    if [ "$desired_name" != "$current_name" ]; then
        hostnamectl set-hostname "$desired_name"
        sed -i "s/$current_name/$desired_name/g" /etc/hosts
        echo "$desired_name" > /etc/hostname
        log_changes "Hostname updated to $desired_name"
    fi
}

# Function to update IP address
update_ip() {
    local desired_ip="$1"
    local current_ip=$(hostname -I | awk '{print $1}')
    if [ "$desired_ip" != "$current_ip" ]; then
        sed -i "/^.*$current_ip.*/c\\$desired_ip $HOSTNAME" /etc/hosts
        sed -i "s/address .*/address $desired_ip/g" /etc/netplan/*.yaml
        netplan apply
        log_changes "IP address updated to $desired_ip"
    fi
}

# Function to update /etc/hosts entry
update_host_entry() {
    local desired_name="$1"
    local desired_ip="$2"
    grep -q "$desired_name" /etc/hosts
    local entry_exists=$?
    if [ $entry_exists -ne 0 ]; then
        echo "$desired_ip $desired_name" >> /etc/hosts
        log_changes "Added $desired_name with IP $desired_ip to /etc/hosts"
    fi
}

# Ignore signals
trap '' TERM HUP INT

# Parse command line arguments
VERBOSE=false
while [ "$#" -gt 0 ]; do
    case "$1" in
        -verbose) VERBOSE=true;;
        -name) update_hostname "$2"; shift;;
        -ip) update_ip "$2"; shift;;
        -hostentry) update_host_entry "$2" "$3"; shift 2;;
        *) echo "Unknown option: $1" >&2;;
    esac
    shift
done

