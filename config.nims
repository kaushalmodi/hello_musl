from macros import error

when NimMajor < 1 and NimMinor <= 19 and NimPatch < 9:
  from ospaths import `/`, splitFile
else:
  from os import `/`, splitFile
