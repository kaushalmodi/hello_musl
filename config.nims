from macros import error
from ospaths import splitFile, `/`

const
  # pcre
  pcreVersion = getEnv("PCREVER", "8.42")
  pcreSourceDir = "pcre-" & pcreVersion
  pcreArchiveFile = pcreSourceDir & ".tar.bz2"
  pcreDownloadLink = "https://downloads.sourceforge.net/pcre/" & pcreArchiveFile
  pcreInstallDir = (thisDir() / "pcre/") & pcreVersion
  # http://www.linuxfromscratch.org/blfs/view/8.1/general/pcre.html
  pcreConfigureCmd = ["./configure", "--prefix=" & pcreInstallDir, "--enable-pcre16", "--enable-pcre32", "--disable-shared"]
  pcreLibDir = pcreInstallDir / "lib"
  pcreIncludeDir = pcreInstallDir / "include"
  pcreLibFile = pcreLibDir / "libpcre.a"

# https://github.com/kaushalmodi/nimy_lisp
proc dollar[T](s: T): string =
  result = $s
proc mapconcat[T](s: openArray[T]; sep = " "; op: proc(x: T): string = dollar): string =
  ## Concatenate elements of ``s`` after applying ``op`` to each element.
  ## Separate each element using ``sep``.
  for i, x in s:
    result.add(op(x))
    if i < s.len-1:
      result.add(sep)

task installPcre, "Installs PCRE using musl-gcc":
  if not existsFile(pcreLibFile):
    if not existsDir(pcreSourceDir):
      if not existsFile(pcreArchiveFile):
        exec("curl -LO " & pcreDownloadLink)
      exec("tar xf " & pcreArchiveFile)
    else:
      echo "PCRE lib source dir " & pcreSourceDir & " already exists"
    withDir pcreSourceDir:
      exec(pcreConfigureCmd.mapconcat())
      putEnv("C", "musl-gcc -static")
      exec("make")
      exec("make install")
  else:
    echo pcreLibFile & " already exists"
  setCommand("nop")

# -d:musl
when defined(musl):
  var
    muslGccPath: string
  echo "  [-d:musl] Building a static binary using musl .."
  muslGccPath = findExe("musl-gcc")
  echo "debug: " & muslGccPath
  if muslGccPath == "":
    error("'musl-gcc' binary was not found in PATH.")
  switch("gcc.exe", muslGccPath)
  switch("gcc.linkerexe", muslGccPath)
  # -d:pcre
  when defined(pcre):
    if not existsFile(pcreLibFile):
      selfExec "installPcre"    # Install PCRE in current dir if pcreLibFile is not found
    switch("passC", "-I" & pcreIncludeDir) # So that pcre.h is found when running the musl task
    switch("define", "usePcreHeader")
    switch("passL", pcreLibFile)
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
  ## Usage: nim musl [-d:pcre] <.nim file path>
  var
    extraDefines = " "
  let
    numParams = paramCount()
  if numParams >= 4:
    error("The 'musl' sub-command accepts at most 2 arguments (but " &
      $(numParams-1) & " were detected)." &
      "\n  Usage Examples: nim musl FILE.nim" &
      "\n                  nim musl -d:pcre FILE.nim")

  when defined(pcre):
    extraDefines.add("-d:pcre")

  let
    nimFile = paramStr(numParams) ## The nim file name *must* be the last.
    (dirName, baseName, _) = splitFile(nimFile)
    binFile = dirName / baseName  # Save the binary in the same dir as the nim file
    nimArgs = "c -d:musl -d:release --opt:size" & extraDefines & " " & nimFile
  # echo "[debug] nimFile = " & nimFile & ", binFile = " & binFile

  # Build binary
  echo "\nRunning 'nim " & nimArgs & "' .."
  selfExec nimArgs

  # Optimize binary
  binOptimize(binFile)

  echo "\nCreated binary: " & binFile
