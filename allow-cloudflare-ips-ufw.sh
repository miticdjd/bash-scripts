#!/bin/bash

set -e

echo "🔒 Setting Cloudflare-only access for ports 80 and 443 (UFW + Docker forwarding)..."

# === Cloudflare IPv4 ===
CF_IPV4=(
"173.245.48.0/20"
"103.21.244.0/22"
"103.22.200.0/22"
"103.31.4.0/22"
"141.101.64.0/18"
"108.162.192.0/18"
"190.93.240.0/20"
"188.114.96.0/20"
"197.234.240.0/22"
"198.41.128.0/17"
"162.158.0.0/15"
"104.16.0.0/13"
"104.24.0.0/14"
"172.64.0.0/13"
"131.0.72.0/22"
)

# === Cloudflare IPv6 ===
CF_IPV6=(
"2400:cb00::/32"
"2606:4700::/32"
"2803:f800::/32"
"2405:b500::/32"
"2405:8100::/32"
"2a06:98c0::/29"
"2c0f:f248::/32"
)

# === Function to add IN rule if not exists ===
add_in_rule() {
    local IP=$1
    local PORT=$2

    if ! ufw status | grep -q "$IP.*$PORT"; then
        ufw allow from "$IP" to any port "$PORT" proto tcp
        echo "✔️ IN  $IP -> port $PORT"
    else
        echo "⏭️ IN  $IP -> port $PORT (exists)"
    fi
}

# === Function to add ROUTE rule if not exists ===
add_route_rule() {
    local IP=$1
    local PORT=$2

    if ! ufw status | grep -q "$IP.*$PORT.*FWD"; then
        ufw route allow proto tcp from "$IP" to any port "$PORT"
        echo "✔️ FWD $IP -> port $PORT"
    else
        echo "⏭️ FWD $IP -> port $PORT (exists)"
    fi
}

# === Apply IPv4 ===
for ip in "${CF_IPV4[@]}"; do
    add_in_rule "$ip" 80
    add_in_rule "$ip" 443

    add_route_rule "$ip" 80
    add_route_rule "$ip" 443
done

# === Apply IPv6 ===
for ip in "${CF_IPV6[@]}"; do
    add_in_rule "$ip" 80
    add_in_rule "$ip" 443

    add_route_rule "$ip" 80
    add_route_rule "$ip" 443
done

echo "🔄 Reloading UFW..."
ufw reload

echo "✅ Done!"
echo "👉 Verify with: ufw status numbered"
