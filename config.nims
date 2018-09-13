from macros import error
from ospaths import splitFile, `/`

# -d:musl
when defined(musl):
  var muslGccPath: string
  echo "  [-d:musl] Building a static binary using musl .."
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
    nimFile = paramStr(numParams) ## The nim file name *must* be the last.
    (dirName, baseName, _) = splitFile(nimFile)
    binFile = dirName / baseName  # Save the binary in the same dir as the nim file
    nimArgs = "c -d:musl -d:release " & nimFile
  # echo "[debug] nimFile = " & nimFile & ", binFile = " & binFile

  # Run nim command
  echo "\nRunning 'nim " & nimArgs & "' .."
  selfExec nimArgs

  # Binary size optimization
  echo ""
  if findExe("strip") != "":
    echo "Running 'strip -s' .."
    exec "strip -s " & binFile
  if findExe("upx") != "":
    # https://github.com/upx/upx/releases/
    echo "Running 'upx' .."
    exec "upx " & binFile

  echo "\nCreated binary: " & binFile
