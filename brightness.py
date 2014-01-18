#!/usr/bin/env python
"""
Python script to essentially perform the same as:

   gdbus call \
       --session \
       --dest org.gnome.SettingsDaemon \
       --object-path /org/gnome/SettingsDaemon/Power \
       --method org.gnome.SettingsDaemon.Power.Screen.SetPercentage 75

References:

    http://ask.fedoraproject.org/question/980/brightness-applet-on-gnome-panel
    http://en.wikibooks.org/wiki/Python_Programming/Dbus
    http://www.devtech.com/inhibitapplet
"""

def set_for_gnome(session_bus):
    proxy = session_bus.get_object("org.gnome.SettingsDaemon",
                                   "/org/gnome/SettingsDaemon/Power")
    dbus_int = dbus.Interface(proxy, "org.gnome.SettingsDaemon.Power.Screen")
    set_percentage = dbus_int.get_dbus_method("SetPercentage")
    return set_percentage


if __name__ == '__main__':
    import sys

    import dbus

    if len(sys.argv) == 1:
        percentage = 40
    else:
        percentage = int(sys.argv[1])

    session_bus = dbus.SessionBus()

    set_percentage(percentage)
