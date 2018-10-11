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
  pcreIncludeDir = pcreInstallDir / "include"
  pcreLibDir = pcreInstallDir / "lib"
  pcreLibFile = pcreLibDir / "libpcre.a"
  # libressl
  sslVersion = getEnv("LIBRESSLVER", "2.8.1")
  sslSourceDir = "libressl-" & sslVersion
  sslArchiveFile = sslSourceDir & ".tar.gz"
  sslDownloadLink = "https://ftp.openbsd.org/pub/OpenBSD/LibreSSL/" & sslArchiveFile
  sslInstallDir = (thisDir() / "libressl/") & sslVersion
  sslSeedConfigOsCompiler = "linux-x86_64"
  sslConfigureCmd = ["./configure", "--disable-shared", "--prefix=" & sslInstallDir]
  sslLibDir = sslInstallDir / "lib"
  sslLibFile = sslLibDir / "libssl.a"
  cryptoLibFile = sslLibDir / "libcrypto.a"
  sslIncludeDir = sslInstallDir / "include/openssl"
  # # openssl
  # sslVersion = getEnv("SSLVER", "1.1.1")
  # sslSourceDir = "openssl-" & sslVersion
  # sslArchiveFile = sslSourceDir & ".tar.gz"
  # sslDownloadLink = "https://www.openssl.org/source/" & sslArchiveFile
  # sslInstallDir = (thisDir() / "openssl/") & sslVersion
  # sslSeedConfigOsCompiler = "linux-x86_64"
  # sslConfigureCmd = ["./Configure", sslSeedConfigOsCompiler, "no-shared", "no-zlib", "-fPIC", "--prefix=" & sslInstallDir]
  # sslLibDir = sslInstallDir / "lib"
  # sslLibFile = sslLibDir / "libssl.a"
  # cryptoLibFile = sslLibDir / "libcrypto.a"
  # sslIncludeDir = sslInstallDir / "include/openssl"

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
      putEnv("C", "musl-gcc -static")
      exec(pcreConfigureCmd.mapconcat())
      exec("make -j8")
      exec("make install")
  else:
    echo pcreLibFile & " already exists"
  setCommand("nop")

task installSsl, "Installs SSL using musl-gcc":
  if (not existsFile(sslLibFile)) or (not existsFile(cryptoLibFile)):
    if not existsDir(sslSourceDir):
      if not existsFile(sslArchiveFile):
        exec("curl -LO " & sslDownloadLink)
      exec("tar xf " & sslArchiveFile)
    else:
      echo "OpenSSL lib source dir " & sslSourceDir & " already exists"
    withDir sslSourceDir:
      putEnv("CC", "musl-gcc -static")
      exec(sslConfigureCmd.mapconcat())
      putEnv("C_INCLUDE_PATH", sslIncludeDir)
      exec("make -j8")
      exec("make install")
  else:
    echo sslLibFile & " already exists"
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
  switch("passL", "-static")
  switch("gcc.exe", muslGccPath)
  switch("gcc.linkerexe", muslGccPath)
  # -d:pcre
  when defined(pcre):
    if not existsFile(pcreLibFile):
      selfExec "installPcre"    # Install PCRE in current dir if pcreLibFile is not found
    switch("passC", "-I" & pcreIncludeDir) # So that pcre.h is found when running the musl task
    switch("define", "usePcreHeader")
    switch("passL", pcreLibFile)
  # -d:ssl
  when defined(ssl):
    if (not existsFile(sslLibFile)) or (not existsFile(cryptoLibFile)):
      selfExec "installSsl"    # Install SSL in current dir if sslLibFile or cryptoLibFile is not found
    switch("passC", "-I" & sslIncludeDir) # So that ssl.h is found when running the musl task
    switch("passL", "-L" & sslLibDir)
    switch("passL", "-lcrypto")
    switch("passL", "-lssl")
    # switch("passL", cryptoLibFile)
    # switch("passL", sslLibFile)
    switch("dynlibOverride", "libcrypto")
    switch("dynlibOverride", "libssl")

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
    switches: seq[string]
    nimFiles: seq[string]
  let
    numParams = paramCount()

  # param 0 will always be "nim"
  # param 1 will always be "musl"
  for i in 2 .. numParams:
    if paramStr(i)[0] == '-':    # -d:foo or --define:foo
      switches.add(paramStr(i))
    else:
      # Non-switch parameters are assumed to be Nim file names.
      nimFiles.add(paramStr(i))

  if nimFiles.len == 0:
    error("The 'musl' sub-command accepts at least one Nim file name" &
      "\n  Usage Examples: nim musl FILE.nim" &
      "\n                  nim musl FILE1.nim FILE2.nim" &
      "\n                  nim musl -d:pcre FILE.nim" &
      "\n                  nim musl -d:pcre -d:ssl FILE.nim")

  for f in nimFiles:
    let
      extraSwitches = switches.mapconcat()
      (dirName, baseName, _) = splitFile(f)
      binFile = dirName / baseName  # Save the binary in the same dir as the nim file
      nimArgsArray = ["c", "-d:musl", "-d:release", "--opt:size", extraSwitches, f]
      nimArgs = nimArgsArray.mapconcat()
    # echo "[debug] f = " & f & ", binFile = " & binFile

    # Build binary
    echo "\nRunning 'nim " & nimArgs & "' .."
    selfExec nimArgs

    # Optimize binary
    binOptimize(binFile)

    echo "\nCreated binary: " & binFile
