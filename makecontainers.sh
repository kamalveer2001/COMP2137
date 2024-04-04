#!/bin/bash

# Script to create simulated servers using containers

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --count)
            COUNT="$2"
            shift
            shift
            ;;
        --fresh)
            FRESH=true
            shift
            ;;
        --prefix)
            PREFIX="$2"
            shift
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Check if prefix is set
if [ -z "$PREFIX" ]; then
    echo "Prefix not provided. Use --prefix option."
    exit 1
fi

# Remove existing containers if --fresh option is set
if [ "$FRESH" = true ]; then
    echo "Removing existing containers..."
    docker rm -f $(docker ps -aq --filter name="$PREFIX")
fi

# Create new containers
for ((i = 1; i <= $COUNT; i++)); do
    docker run -d --name "$PREFIX$i" --hostname "$PREFIX$i" alpine tail -f /dev/null
done

# Print summary of hosts and IP addresses
echo "Summary of hosts and IP addresses:"
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps -aq --filter name="$PREFIX") | awk '{printf("Server %s: %s\n", NR, $0)}'

