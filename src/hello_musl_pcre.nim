import re

let
  s = "Hello, World!"
  regex = re"H...."
echo(s)
echo s.replace(regex, "Bye")
