for path in /sys/class/drm/card0-*;
do
    state=`cat $path/status`
    if [ $state = 'connected' ]
    then
        echo ${path#/sys/class/drm/card0-}
    fi
done
