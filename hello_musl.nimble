# Package

version       = "0.1.0"
author        = "Kaushal Modi"
description   = "Example of statically building a Nim binary using musl"
license       = "MIT"
srcDir        = "src"
bin           = @["hello_musl"]

# Dependencies

requires "nim >= 0.18.1"        # For findExe in nimscript

import ospaths # for `/`
import macros  # for error, used in checkMusl

let
  pkgName = "hello_musl"
  srcFile = "src" / (pkgName & ".nim")
  binFile = pkgName

var muslGcc: string

proc checkMusl() =
  ## Check if ``musl-gcc`` exists.
  muslGcc = findExe("musl-gcc")
  # echo "debug: " & muslGcc
  if muslGcc == "":
    error("You need to have the musl library installed, and the musl-gcc binary in PATH.")

task musl, "Builds an optimized static binary using musl":
  checkMusl()
  rmFile binFile
  exec "nim -d:musl -d:release --out:" & binFile & " c " & srcFile
  if findExe("strip") == "":
    exec "strip -s " & binFile
  else:
    echo binFile & " was not stripped"
