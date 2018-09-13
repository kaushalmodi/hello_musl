from macros import error
from ospaths import `/`
from strutils import toLowerAscii

# -d:musl
when defined(musl):
  var muslGccPath: string
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
  if numParams != 2:
    error("The 'musl' sub-command needs exactly 1 argument, the Nim file (but " &
      $(numParams-1) & " were detected)." &
      "\n  Usage Example: nim musl FILE.nim.")

  let
    # The nim file name must be the last.
    nimFile = paramStr(numParams)
    nimFileLen = len(nimFile)
  # echo "[debug] nimFile = " & nimFile

  var binFile = nimFile
  if (nimFileLen > 4) and (nimFile[(nimFileLen-4) ..< nimFileLen].toLowerAscii == ".nim"):
    # Strip off the trailing ".nim" extension if it exists.
    binFile = nimFile[0 ..< (nimFileLen-4)]
  # echo "[debug] binFile = " & binFile

  # Run nim command
  let
    nimArgs = "-d:musl -d:release --out:" & binFile & " c " & nimFile
  echo "\nRunning 'nim " & nimArgs & "' .."
  selfExec nimArgs

  if findExe("strip") != "":
    echo "\nRunning 'strip -s' .."
    exec "strip -s " & binFile

  if findExe("upx") != "":
    # https://github.com/upx/upx/releases/
    echo "\nRunning 'upx' .."
    exec "upx " & binFile

  echo "\nCreated binary: " & binFile
