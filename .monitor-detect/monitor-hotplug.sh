#!/bin/env sh

PATH_TO_SELF=`dirname $0`
USER=`ls /home/*/.Xauthority | head -n 1 | cut -d/ -f 3`
PATH_TO_MONITORS=/sys/class/drm/card0-
PATH_TO_CONFS=$PATH_TO_SELF/monitors
LOG_FILE=$PATH_TO_SELF/monitor-detect.log

log() {
    d=`date "+%Y-%m-%d %H:%M"`
    echo "$d $1" >> $LOG_FILE
}

test_exists() {
    filename=$1
    if [ ! -f $filename ]
    then
        log "E: File $filename does not exist"
        exit -1
    fi
}

find_mode_for() {
    screen_name=$1
    screen_id=$2

    if [ -f $PATH_TO_CONFS/$screen_id/mode ]
    then
        read -a < $PATH_TO_CONFS/$screen_id/mode mode
    else
        test_exists "$PATH_TO_MONITORS$screen_name/modes"
        mode=`head -n 1 $PATH_TO_MONITORS$screen_name/modes`
        log "W: mode conf file for screen $screen_name ($screen_id) not found, using $mode"
    fi
    echo $mode
}

##################################
# For Xrandr to find the display #
##################################
displaynum=`ls /tmp/.X11-unix/* | sed s#/tmp/.X11-unix/X##`
#display=":$displaynum"
export DISPLAY=":$displaynum"
#export DISPLAY=":0"
export XAUTHORITY=/home/$USER/.Xauthority

#########################################
# Get the properties of the main screen #
#########################################

test_exists "$PATH_TO_CONFS/main/name"
read -a < $PATH_TO_CONFS/main/name main_name

main_mode=`find_mode_for "$main_name" "main"`
log "I: Main screen name: $main_name"
log "I: Main screen mode: $main_mode"

##################################################
# Get the properties of the external monitor(s?) #
##################################################

external_screen_found=false
for path in $PATH_TO_MONITORS*
do
    state=`cat $path/status`
    if [ $state = 'connected' ]
    then
        # Get the screen name (eg. VGA-1)
        name=${path#$PATH_TO_MONITORS}
        # If this is not the main screen 
        if [ $name != $main_name ]
        then
            external_screen_found=true
            # Screens are identified by the SHA1 of their edid
            h=`sha1sum $path/edid | cut -d' ' -f1`
            mode=`find_mode_for "$name" "$h"`
            log "I: External screen name: $name"
            log "I: External screen mode: $mode"
            # Configure the screen layout using xrandr
            xrandr --output ${name//-/} --off >> $LOG_FILE 2>&1
            xrandr --output ${main_name//-/} --mode $main_mode \
                --output ${name//-/} --mode $mode --above ${main_name//-/} >> $LOG_FILE 2>&1
        fi
    fi
done

# If no external monitor was found connected
# turn all external monitors off except the
# main one
if [ "$external_screen_found" = "false" ]
then
    log "I: No external monitor, keeping only main monitor on"
    for path in $PATH_TO_MONITORS*
    do
        name=${path#$PATH_TO_MONITORS}
        if [ $name != $main_name ]
        then
            xrandr --output ${name//-/} --off
        fi
    done
fi
