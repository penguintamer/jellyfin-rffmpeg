#!/bin/sh
set -e

# ssh needs a passwd entry for the running uid
if ! getent passwd "$(id -u)" >/dev/null; then
  NSS_WRAPPER_PASSWD=$(mktemp /tmp/passwd.XXXXXX)
  NSS_WRAPPER_GROUP=$(mktemp /tmp/group.XXXXXX)
  cp /etc/passwd "$NSS_WRAPPER_PASSWD"
  cp /etc/group "$NSS_WRAPPER_GROUP"
  echo "jellyfin:x:$(id -u):$(id -g):Jellyfin:${JELLYFIN_DATA_DIR:-/config}:/usr/sbin/nologin" >> "$NSS_WRAPPER_PASSWD"
  getent group "$(id -g)" >/dev/null || echo "jellyfin:x:$(id -g):" >> "$NSS_WRAPPER_GROUP"
  export NSS_WRAPPER_PASSWD NSS_WRAPPER_GROUP LD_PRELOAD="libnss_wrapper.so${LD_PRELOAD:+ $LD_PRELOAD}"
fi

exec "$@"
