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

proc binOptimize(binFile: string) =
  ## Optimize size of the ``binFile`` binary.
  echo ""
  if findExe("strip") != "":
    echo "Running 'strip -s' .."
    exec "strip -s " & binFile
  if findExe("upx") != "":
    # https://github.com/upx/upx/releases/
    echo "Running 'upx --best' .."
    exec "upx --best " & binFile

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
    nimArgs = "c -d:musl -d:release --opt:size " & nimFile
  # echo "[debug] nimFile = " & nimFile & ", binFile = " & binFile

  # Build binary
  echo "\nRunning 'nim " & nimArgs & "' .."
  selfExec nimArgs

  # Optimize binary
  binOptimize(binFile)

  echo "\nCreated binary: " & binFile
