#! /bin/sh

#inputplug script to refresh gnome settings when new keyboard is plugged in

#echo >&2 "$@"
event=$1 id=$2 type=$3

case "$event $type" in
'XIDeviceEnabled XISlaveKeyboard')
	gsettings set org.gnome.desktop.input-sources xkb-options "['lv3:ralt_switch_multikey', 'eurosign:5']"
	gsettings set org.gnome.desktop.input-sources xkb-options "['lv3:ralt_switch_multikey', 'eurosign:5', 'caps:escape_shifted_capslock']"
esac
