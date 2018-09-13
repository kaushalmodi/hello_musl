import macros  # for error
import ospaths # for `/`

# -d:musl
var muslGccPath: string
when defined(musl):
  echo "Building a static binary using musl .."
  muslGccPath = findExe("musl-gcc")
  # echo "debug: " & muslGccPath
  if muslGccPath == "":
    error("'musl-gcc' binary was not found in PATH.")
  switch("gcc.exe", muslGccPath)
  switch("gcc.linkerexe", muslGccPath)
  switch("passL", "-static")
  switch("opt", "size")

# nim musl foo.nim
task musl, "Builds an optimized static binary using musl":
  ## Usage: nim musl <.nim file path>
  let
    numParams = paramCount()
  if numParams <= 1:
    error("The 'musl' sub-command needs the Nim file-name argument. Example: nim musl FILE.nim.")

  let
    # The nim file name must be the last.
    nimFile = paramStr(numParams)
    nimFileLen = len(nimFile)
  # echo "[debug] nimFile = " & nimFile

  var binFile = nimFile
  if (nimFileLen > 4) and (nimFile[(nimFileLen-4) ..< nimFileLen] == ".nim"):
    # Strip off the trailing ".nim" extension if it exists.
    binFile = nimFile[0 ..< (nimFileLen-4)]
  # echo "[debug] binFile = " & binFile

  rmFile binFile
  exec "nim -d:musl -d:release --out:" & binFile & " c " & nimFile
  if findExe("strip") != "":
    echo "Running 'strip -s' .."
    exec "strip -s " & binFile
  if findExe("upx") != "":
    echo "Running 'upx' .."
    exec "upx " & binFile
