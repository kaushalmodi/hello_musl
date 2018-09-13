# Package

version       = "0.1.0"
author        = "Kaushal Modi"
description   = "Example of statically building a Nim binary using musl"
license       = "MIT"
srcDir        = "src"
bin           = @["hello_musl"]


# Dependencies

requires "nim >= 0.18.1"

import ospaths # for `/`
let
  pkgName = "hello_musl"
  srcFile = "src" / (pkgName & ".nim")
  binFile = pkgName

task stat, "Builds an optimized static binary using musl":
  rmFile binFile
  exec "nim musl -d:release --out:" & binFile & " " & srcFile
  exec "strip -s " & binFile
