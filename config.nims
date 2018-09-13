# -d:musl
when defined(musl):
  # ~ does not work in the paths below
  const muslGcc = "/home/kmodi/stowed/bin/musl-gcc"

  echo "Building a static binary using musl .."
  switch("gcc.exe", muslGcc)
  switch("gcc.linkerexe", muslGcc)
  switch("passL", "-static")
  switch("opt", "size")
