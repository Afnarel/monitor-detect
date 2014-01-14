monitor-detect
==============

This script detects the monitors currently connected to the computer and sets
their resolution. The resolution can be set manually in a file for each
monitor. If no configuration is found, the script attempts to set the highest
resolution for each monitor.

This is not meant to be a user-friendly tool.

Installation
------------

    * Copy the `.monitor-detect` directory wherever you want on your disk
      (~/.monitor-detect is a good place). It is better to put it somewhere it
      can be executed by a regular user.
    * Copy `99-monitor-hotplug.rules` to `/etc/udev/rules.d`. Then, edit
      `/etc/udev/rules.d/99-monitor-hotplug.rules` and update the (absolute)
      path to the `monitor-hotplug.sh` script. This will enable udev to 
      launch the `monitor-hotplug.sh` script automatically when an external
      monitor will be detected.
    * Edit the file `.monitor-detect/monitors/main/name` and put the name of
      your main screen in it (the one that should always be on). You can find
      it by disconnecting all the other monitors and executing
      `.monitor-detect/available-monitors.sh`.

Configuration
-------------

    To set a static configuration for a given screen:

    * Find out its name: you can use the `.monitor-detect/available-monitors.sh` 
      script and connect/disconnect the monitor to see which one appears or disappears.
    * Create a directory in `.monitor-detects/monitors` whose name is the
      SHA-1 sum of the edid file of the monitor. You can find it by running
      `sha1sum /sys/class/drm/card0-*/edid`. For the main screen, the `main`
      directory must be used instead.
    * In this directory, create a file named `mode` and put the resolution you
      want to use in it. Available modes for the screen can be found with
      something like: `cat /sys/class/drm/card0-DP-1/modes` or with `xrandr`.
      It looks like: `1920x1080`.

Solving errors
--------------

If the `monitor-hotplug.sh` script does not work, look at the log file in
`.monitor-detect/monitor-detect.log`. It might contain interesting
information.

Development notes
-----------------

[Main source](http://stackoverflow.com/questions/5469828/how-to-create-a-callback-for-monitor-plugged-on-an-intel-graphics)

Running `udevadm monitor --property` as root and dis/connecting an external
monitor, udev events were shown.

I created the file `/etc/udev/rules.d/99-monitor-hotplug.rules` and put the
following in it:
    ACTION=="change", SUBSYSTEM=="drm", ENV{HOTPLUG}=="1", RUN+="/path/to/monitor-hotplug.sh"
