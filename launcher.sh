#!/bin/bash
SCRIPT_HOME=$( cd -P -- "$(dirname -- "$(command -v -- "$0")")" && pwd -P )
display="DISPLAY=:0.0"

echo `date -d now +%Y%m%d%H%M%S` > /tmp/.awaytime

$SCRIPT_HOME/pidgin_status.sh $display

dbus-monitor --system "type='signal',sender='org.freedesktop.login1',path='/org/freedesktop/login1/seat/seat0',interface='org.freedesktop.DBus.Properties',member='PropertiesChanged'" | grep --line-buffered "ActiveSession" | while read line; do $SCRIPT_HOME/away.sh $display;xfce4-panel -r; xmodmap ~/.Xmodmap; kill $(ps aux | grep fce4-display-settings\ --minimal | awk '{print $2}'); done
