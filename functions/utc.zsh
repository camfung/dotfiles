utc() {
  TZ=America/Los_Angeles date -d "$1 UTC" '+%Z %H:%M' | tr 'A-Z' 'a-z'
}
