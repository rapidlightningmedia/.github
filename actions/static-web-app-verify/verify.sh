#!/usr/bin/env bash
#
# The shared Static Web App deploy check (rlm-ops#559). action.yml, next to this file, runs it
# after an upload. It also runs by hand, which is how the fix was proven:
#
#   HOST=<app>.azurestaticapps.net BUILD_DIR=build BUILD_ID=<commit sha> bash verify.sh
#
# The first check waits until the live site serves THIS build. Nothing else is checked until it
# does, because every other check also passes against the site that was live before the deploy.
#
# How it knows: static-web-app-stamp wrote the commit SHA to _deploy/build-id.txt inside the build
# folder before the upload. Until the new content is live, that path answers with the previous
# build's SHA or with the fallback HTML page. Neither can equal this SHA.

set -uo pipefail

: "${HOST:?HOST is required (the Static Web App default hostname)}"
: "${BUILD_DIR:?BUILD_DIR is required (the folder that was uploaded)}"
: "${BUILD_ID:?BUILD_ID is required (the commit SHA the stamp wrote)}"
WAIT_SECONDS="${WAIT_SECONDS:-300}"
POLL_SECONDS="${POLL_SECONDS:-10}"
FALLBACK_PATH="${FALLBACK_PATH:-/definitely-not-a-real-route}"

BASE="https://$HOST"
MARKER_PATH="/_deploy/build-id.txt"

fail=0
step_ok=1
error() {
  echo "::error::$*"
  fail=1
  step_ok=0
}

sha256() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum | cut -d' ' -f1; else shasum -a 256 | cut -d' ' -f1; fi
}

# One header's value from a set of response headers, matched without regard to case.
header_value() { # headers name
  printf '%s\n' "$1" | grep -i "^$2:" | tail -1 | cut -d: -f2- | sed 's/^ *//'
}

echo "Checking $BASE for build $BUILD_ID"

echo "== 1. The live site serves this build =="
deadline=$(($(date +%s) + WAIT_SECONDS))
attempt=0
while :; do
  attempt=$((attempt + 1))
  # A new query string on every attempt, so no cache between here and Azure can hand back an
  # earlier answer.
  got=$(curl -sS --max-time 20 "$BASE$MARKER_PATH?attempt=$attempt" 2>/dev/null | head -c 200 | tr -d '[:space:]')
  if [ "$got" = "$BUILD_ID" ]; then
    echo "  ok: $MARKER_PATH is $BUILD_ID (attempt $attempt)"
    break
  fi
  case "$got" in
    "") seen="no answer" ;;
    "<"*) seen="the fallback HTML page (no build id is deployed there)" ;;
    *) seen="build ${got:0:40} (not this one)" ;;
  esac
  if [ "$(date +%s)" -ge "$deadline" ]; then
    echo "::error::after ${WAIT_SECONDS}s, $BASE$MARKER_PATH still answers with $seen, not build $BUILD_ID. This deploy is NOT live. Nothing else was checked, because every other check also passes against the site that was live before."
    exit 1
  fi
  echo "  waiting: $MARKER_PATH answers with $seen (attempt $attempt); next try in ${POLL_SECONDS}s"
  sleep "$POLL_SECONDS"
done

echo "== 2. The live root is this build's index.html =="
step_ok=1
if [ ! -f "$BUILD_DIR/index.html" ]; then
  error "$BUILD_DIR/index.html does not exist. BUILD_DIR must be the folder that was uploaded."
else
  want=$(sha256 <"$BUILD_DIR/index.html")
  have=$(curl -sS --max-time 20 "$BASE/" | sha256)
  if [ "$want" != "$have" ]; then
    error "the live root is not $BUILD_DIR/index.html (built ${want:0:12}, live ${have:0:12})"
  fi
fi
[ "$step_ok" = 1 ] && echo "  ok: / matches $BUILD_DIR/index.html"

echo "== 3. The root is no-cache =="
step_ok=1
root_headers=$(curl -sS --max-time 20 -D - -o /dev/null "$BASE/" | tr -d '\r')
root_cc=$(header_value "$root_headers" cache-control)
echo "  cache-control: $root_cc"
case "$root_cc" in
  *no-cache*) ;;
  *) error "the root is not no-cache (was: '$root_cc')" ;;
esac
[ "$step_ok" = 1 ] && echo "  ok"

echo "== 4. A hashed asset is real CSS or JavaScript, and immutable =="
step_ok=1
asset=$(grep -oE "_app/immutable/[^\"' )]+\.(js|css)" "$BUILD_DIR/index.html" 2>/dev/null | head -1)
if [ -z "$asset" ]; then
  error "$BUILD_DIR/index.html references no hashed asset under _app/immutable/"
else
  asset="/$asset"
  asset_headers=$(curl -sS --max-time 20 -D - -o /dev/null -w 'HTTPCODE %{http_code}\n' "$BASE$asset" | tr -d '\r')
  asset_code=$(printf '%s\n' "$asset_headers" | sed -n 's/^HTTPCODE //p')
  asset_type=$(header_value "$asset_headers" content-type)
  asset_cc=$(header_value "$asset_headers" cache-control)
  echo "  $asset -> $asset_code | $asset_type | $asset_cc"
  [ "$asset_code" = "200" ] || error "$asset returned $asset_code, not 200"
  # The fallback answers a MISSING asset with 200, text/html AND the immutable header, because the
  # route rule matches the path, not the file. Only the content type tells a real asset apart.
  case "$asset_type" in
    text/css* | *javascript*) ;;
    *) error "$asset came back as '$asset_type', not CSS or JavaScript. That is the fallback page, so the asset is not live." ;;
  esac
  case "$asset_cc" in
    *immutable*) ;;
    *) error "$asset lacks the immutable header (was: '$asset_cc')" ;;
  esac
fi
[ "$step_ok" = 1 ] && echo "  ok"

echo "== 5. An unknown path falls back to the app, not a 404 =="
step_ok=1
fallback=$(curl -sS --max-time 20 -o /dev/null -w '%{http_code} %{content_type}' "$BASE$FALLBACK_PATH")
echo "  $FALLBACK_PATH -> $fallback"
case "$fallback" in
  "200 text/html"*) ;;
  *) error "the navigation fallback is missing ($FALLBACK_PATH answered '$fallback', not 200 text/html)" ;;
esac
[ "$step_ok" = 1 ] && echo "  ok"

exit "$fail"
