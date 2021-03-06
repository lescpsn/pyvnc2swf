#!/bin/bash
#
# record.sh -- record vnc session
#

TOP_DIR=$(cd $(dirname $0) && pwd)/../

RECORDER=${TOP_DIR}/pyvnc2swf/vnc2swf.py
TOOLS=${TOP_DIR}/tools/
CONFIG=${TOOLS}/config

[ -z "$OUTTYPE" ] && OUTTYPE=vnc
[ -z "$DEBUG" ] && DEBUG=0
[ -z "$PASSWD" ] && PASSWD=1
[ -z "$CURSOR" ] && CURSOR=1
[ -z "$CONSOLE" ] && CONSOLE=0
[ -z "$SERVER" ] && SERVER=1 && PASSWD=1

. ${CONFIG}

[ -z "$RECORDINGS" ] && RECORDINGS=$VNC_RECORDINGS
[ -z "$CONSOLE" ] && CONSOLE=$VNC_CONSOLE
[ -z "$CURSOR" ] && CURSOR=$VNC_CURSOR
[ -z "$SCREEN_SIZE" ] && SCREEN_SIZE=$VNC_SCREEN_SIZE
[ -z "$FPS" ] && FPS=$VNC_FPS

VNC_TARGET=$1
if [ -n "$VNC_TARGET" ]; then
    VNC_SERVER=${VNC_TARGET%:*}
    (echo $VNC_TARGET | grep -q ":") && VNC_PORT=${VNC_TARGET#*:}
    [ -z "$VNC_PORT" ] && VNC_PORT=5900
fi

VNC_PWD_FILE=${TOOLS}/$VNC_PWD_FILE
VNC_PWD_FILE=$(cd $(dirname $VNC_PWD_FILE) && pwd)/$(basename $VNC_PWD_FILE)
if [ $PASSWD -eq 1 ]; then
    x11vnc -storepasswd $VNC_PWD $VNC_PWD_FILE
    PASSWD_OPT=" -P $VNC_PWD_FILE "
fi
if [ $VNC_SERVER == "localhost" -a $SERVER -eq 1 ]; then
    ps -ef | grep -v grep | grep -q "x11vnc.*forever.*viewonly.*localhost"
    if [ $? -ne 0 ]; then
        #pkill x11vnc
        #x11vnc -scale $SCREEN_SIZE  -quiet -cursor -viewonly -bg -localhost -wait 10 -defer 10 -rfbauth $VNC_PWD_FILE
        #x11vnc -quiet -cursor -viewonly -bg -localhost -rfbauth $VNC_PWD_FILE
        x11vnc -quiet -forever -viewonly -bg -localhost -rfbauth $VNC_PWD_FILE
    fi
fi

VNC_RECORD_DIR=${RECORDINGS}/`date -u +"%Y-%m-%d"`
[ ! -d $VNC_RECORD_DIR ] && mkdir $VNC_RECORD_DIR

VNC_RECORD_FILE=${VNC_RECORD_DIR}/${VNC_RECORD_FILE}.${OUTTYPE}
VNC_RECORD_FILE=$(cd $(dirname $VNC_RECORD_FILE) && pwd)/$(basename $VNC_RECORD_FILE)
OUTFILE=" -o $VNC_RECORD_FILE "

CURSOR_OPT=" -N "
[ "$CURSOR" == "1" ] && CURSOR_OPT=""

CONSOLE_OPT=""
[ "$CONSOLE" == "1" ] && CONSOLE_OPT=" -n "

[ -n "$FPS" ] && FPS_OPT=" -r $FPS "
[ $DEBUG -eq 1 ] && DEBUG_OPT=" -d "

[ "$VNC_SERVER" == "localhost" ] && xrandr -s $SCREEN_SIZE
$RECORDER $CURSOR_OPT $CONSOLE_OPT $FPS_OPT $DEBUG_OPT $PASSWD_OPT $OUTFILE -t $OUTTYPE $VNC_SERVER $VNC_PORT
[ "$VNC_SERVER" == "localhost" ] && xrandr -s 0
