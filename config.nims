import macros  # for error, used in checkMusl

var muslGcc: string

proc checkMusl() =
  ## Check if ``musl-gcc`` exists.
  muslGcc = findExe("musl-gcc")
  echo "debug: " & muslGcc
  if muslGcc == "":
    error("You need to have the musl library installed, and the musl-gcc binary in PATH.")

# -d:musl
when defined(musl):
  checkMusl()
  echo "Building a static binary using musl .."
  switch("gcc.exe", muslGcc)
  switch("gcc.linkerexe", muslGcc)
  switch("passL", "-static")
  switch("opt", "size")
