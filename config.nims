# -d:musl
when defined(musl):
  echo "Building a static binary using musl .."
  switch("gcc.exe", muslGcc)
  switch("gcc.linkerexe", muslGcc)
  switch("passL", "-static")
  switch("opt", "size")
