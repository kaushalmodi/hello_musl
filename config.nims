task musl, "Builds a static binary using musl":
  # ~ does not work in the paths below
  const muslGcc = "/home/kmodi/stowed/bin/musl-gcc"
  switch("gcc.exe", muslGcc)
  switch("gcc.linkerexe", muslGcc)
  switch("passL", "-static")
  switch("opt", "size")
  setCommand "c"
