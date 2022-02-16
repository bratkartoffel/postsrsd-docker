#!/bin/ash

# exit when any command fails
set -o errexit -o pipefail

# configuration
: "${APP_UID:=504}"
: "${APP_GID:=504}"
: "${APP_UMASK:=027}"
: "${APP_USER:=postsrsd}"
: "${APP_GROUP:=postsrsd}"
: "${APP_HOME:=/run/postsrsd}"
: "${APP_SECRETS_FILE:=/etc/postsrsd.secrets}"
: "${APP_PORT_FOR:=10001}"
: "${APP_PORT_REV:=10002}"
: "${APP_DOMAIN:=example.com}"
: "${APP_ADDITIONAL_PARAMS:=}"

# export configuration
export APP_PORT_FOR APP_PORT_REV APP_SECRETS_FILE APP_DOMAIN APP_ADDITIONAL_PARAMS

# invoked as root, add user and prepare container
if [ "$(id -u)" -eq 0 ]; then
  echo ">> removing default user and group"
  if getent passwd "$APP_USER" >/dev/null; then deluser "$APP_USER"; fi
  if getent group "$APP_GROUP" >/dev/null; then delgroup "$APP_GROUP"; fi

  echo ">> adding unprivileged user (uid: $APP_UID / gid: $APP_GID)"
  addgroup -g "$APP_GID" "$APP_GROUP"
  adduser -HD -h "$APP_HOME" -s /sbin/nologin -G "$APP_GROUP" -u "$APP_UID" -k /dev/null "$APP_USER"

  echo ">> fixing owner of $APP_HOME"
  install -dm 0750 -o "$APP_USER" -g "$APP_GROUP" "$APP_HOME"
  touch "$APP_SECRETS_FILE"
  chown -R "$APP_USER":"$APP_GROUP" "$APP_HOME" "$APP_SECRETS_FILE" /etc/s6

  echo ">> create link for syslog redirection"
  install -dm 0750 -o "$APP_USER" -g "$APP_GROUP" /run/syslogd
  ln -s /run/syslogd/syslogd.sock /dev/log

  # drop privileges and re-execute this script unprivileged
  echo ">> dropping privileges"
  export HOME="$APP_HOME" USER="$APP_USER" LOGNAME="$APP_USER" PATH="/usr/local/bin:/bin:/usr/bin"
  exec /usr/bin/setpriv --reuid="$APP_USER" --regid="$APP_GROUP" --init-groups --inh-caps=-all "$0" "$@"
fi

# tighten umask for newly created files / dirs
echo ">> changing umask to $APP_UMASK"
umask "$APP_UMASK"

echo ">> starting application"
exec /bin/s6-svscan /etc/s6

# vim: set ft=bash ts=2 sts=2 expandtab:

