import httpclient, json

var client = newHttpClient()
let jObj = client.getContent("https://scripter.co/jf2feed.json").parseJson()
echo jObj["author"]
echo jObj["author"].pretty()
echo jObj["author"]["name"]
