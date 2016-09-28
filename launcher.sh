#!/bin/bash
SCRIPT_HOME=$( cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P )

echo `date -d now +%Y%m%d%H%M%S` > /tmp/.awaytime

$SCRIPT_HOME/pidgin_status.sh

dbus-monitor --system "type='signal',sender='org.freedesktop.login1',path='/org/freedesktop/login1/seat/seat0',interface='org.freedesktop.DBus.Properties',member='PropertiesChanged'" | grep --line-buffered "ActiveSession" | while read line; do $SCRIPT_HOME/away.sh; done
