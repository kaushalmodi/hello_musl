from macros import error
from ospaths import splitFile, `/`

const
  doOptimize = true
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
  # openssl
  openSslSeedConfigOsCompiler = "linux-x86_64"
  openSslVersion = getEnv("OPENSSLVER", "1.1.1")
  openSslSourceDir = "openssl-" & openSslVersion
  openSslArchiveFile = openSslSourceDir & ".tar.gz"
  openSslDownloadLink = "https://www.openssl.org/source/" & openSslArchiveFile
  openSslInstallDir = (thisDir() / "openssl/") & openSslVersion
  # "no-async" is needed for openssl to compile using musl
  #   - https://gitter.im/nim-lang/Nim?at=5bbf75c3ae7be940163cc198
  #   - https://www.openwall.com/lists/musl/2016/02/04/5
  # -DOPENSSL_NO_SECURE_MEMORY is needed to make openssl compile using musl.
  #   - https://github.com/openssl/openssl/issues/7207#issuecomment-420814524
  openSslConfigureCmd = ["./Configure", openSslSeedConfigOsCompiler, "no-shared", "no-zlib", "no-async", "-fPIC", "-DOPENSSL_NO_SECURE_MEMORY", "--prefix=" & openSslInstallDir]
  openSslLibDir = openSslInstallDir / "lib"
  openSslLibFile = openSslLibDir / "libssl.a"
  openCryptoLibFile = openSslLibDir / "libcrypto.a"
  openSslIncludeDir = openSslInstallDir / "include/openssl"
  # libressl
  libreSslVersion = getEnv("LIBRESSLVER", "2.8.1")
  libreSslSourceDir = "libressl-" & libreSslVersion
  libreSslArchiveFile = libreSslSourceDir & ".tar.gz"
  libreSslDownloadLink = "https://ftp.openbsd.org/pub/OpenBSD/LibreSSL/" & libreSslArchiveFile
  libreSslInstallDir = (thisDir() / "libressl/") & libreSslVersion
  libreSslConfigureCmd = ["./configure", "--disable-shared", "--prefix=" & libreSslInstallDir]
  libreSslLibDir = libreSslInstallDir / "lib"
  libreSslLibFile = libreSslLibDir / "libssl.a"
  libreCryptoLibFile = libreSslLibDir / "libcrypto.a"
  libreSslIncludeDir = libreSslInstallDir / "include/openssl"

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

task installOpenSsl, "Installs OPENSSL using musl-gcc":
  if (not existsFile(openSslLibFile)) or (not existsFile(openCryptoLibFile)):
    if not existsDir(openSslSourceDir):
      if not existsFile(openSslArchiveFile):
        exec("curl -LO " & openSslDownloadLink)
      exec("tar xf " & openSslArchiveFile)
    else:
      echo "OpenSSL lib source dir " & openSslSourceDir & " already exists"
    withDir openSslSourceDir:
      putEnv("CC", "musl-gcc -static")
      putEnv("C_INCLUDE_PATH", openSslIncludeDir)
      exec(openSslConfigureCmd.mapconcat())
      exec("make -j8 depend")
      exec("make -j8")
      exec("make install")
  else:
    echo openSslLibFile & " already exists"
  setCommand("nop")

task installLibreSsl, "Installs LIBRESSL using musl-gcc":
  if (not existsFile(libreSslLibFile)) or (not existsFile(libreCryptoLibFile)):
    if not existsDir(libreSslSourceDir):
      if not existsFile(libreSslArchiveFile):
        exec("curl -LO " & libreSslDownloadLink)
      exec("tar xf " & libreSslArchiveFile)
    else:
      echo "LibreSSL lib source dir " & libreSslSourceDir & " already exists"
    if getEnv("TRAVIS_LIBRESSL_HACK") == "1":
      # https://gitter.im/nim-lang/Nim?at=5bbf9370bbdc0b250524cf46
      # Add "#undef SYS__sysctl" to the beginning of <libressl source>/crypto/compat/getentropy_linux.c.
      let
        hackedFile = libreSslSourceDir / "crypto/compat/getentropy_linux.c"
        hackedFileBkp = hackedFile & ".bkp"
      if existsFile hackedFileBkp:
        cpFile(hackedFileBkp, hackedFile) # restore from backup
      else:
        cpFile(hackedFile, hackedFileBkp) # do a backup
      exec("sed -i '1s/^/#undef SYS__sysctl /' " & hackedFile)
    withDir libreSslSourceDir:
      putEnv("CC", "musl-gcc -static")
      putEnv("C_INCLUDE_PATH", libreSslIncludeDir)
      exec(libreSslConfigureCmd.mapconcat())
      exec("make -j8")
      exec("make install")
  else:
    echo libreSslLibFile & " already exists"
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
    const
      useOpenSsl = (getEnv("USE_LIBRESSL") == "") or (getEnv("USE_LIBRESSL") == "0") # Uses libreSsl if false
    var
      sslLibFile: string
      cryptoLibFile: string
      sslIncludeDir: string
      sslLibDir: string
    if useOpenSsl:
      sslLibFile = openSslLibFile
      cryptoLibFile = openCryptoLibFile
      sslIncludeDir = openSslIncludeDir
      sslLibDir = openSslLibDir
    else:
      sslLibFile = libreSslLibFile
      cryptoLibFile = libreCryptoLibFile
      sslIncludeDir = libreSslIncludeDir
      sslLibDir = libreSslLibDir

    if (not existsFile(sslLibFile)) or (not existsFile(cryptoLibFile)):
      # Install SSL in current dir if sslLibFile or cryptoLibFile is not found
      if useOpenSsl:
        selfExec "installOpenSsl"
      else:
        selfExec "installLibreSsl"
    switch("passC", "-I" & sslIncludeDir) # So that ssl.h is found when running the musl task
    switch("passL", "-L" & sslLibDir)
    switch("passL", "-lssl")
    switch("passL", "-lcrypto") # This *has* to come *after* -lssl
    switch("dynlibOverride", "libssl")
    switch("dynlibOverride", "libcrypto")

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
      nimArgsArray = when doOptimize:
                       ["c", "-d:musl", "-d:release", "--opt:size", extraSwitches, f]
                     else:
                       ["c", "-d:musl", extraSwitches, f]
      nimArgs = nimArgsArray.mapconcat()
    # echo "[debug] f = " & f & ", binFile = " & binFile

    # Build binary
    echo "\nRunning 'nim " & nimArgs & "' .."
    selfExec nimArgs

    when doOptimize:
      # Optimize binary
      binOptimize(binFile)

    echo "\nCreated binary: " & binFile
