
logmsg() {
    _msg=$*
    [ -n "$VERBOSE" ] && echo $_msg
    [ -n "$LOGFILE" ] && echo $_msg >>$LOGFILE
    [ -n "$SYSLOG" ]  && logger -t exist-filebased-backup $_msg
}

logerr() {
    _excode=$1
    shift
    _msg=$*
    [ -n "$VERBOSE" ] && echo $_msg >&2
    [ -n "$LOGFILE" ] && echo $_msg >>$LOGFILE
    [ -n "$SYSLOG"  ] && logger -t exist-filebased-backup -p error $_msg
    echo "exiting, logfile $LOGFILE" >&2
    exit $_excode
}

ask_stop() {
    if [ -z "$FORCE" ]; then
	echo -n "This will STOP the exist instance before doing the backup. Proceed? [yN] "
	read proceed
	case "$proceed" in
	    y|Y) :;;
	    *) logerr 1 "Aborted by user"; exit 1;;
	esac
    fi
}

# if eXist instance is running, stop it first
shutdown_exist() {
    if psexist -S $INSTNAME | grep -q "instance: $INSTNAME"; then
        ask_stop
	logmsg "Stopping running eXist instance \"${INSTNAME}\""
	service ${INSTNAME} stop
	# check again to verify it is really dead, just to be sure
	sleep $DEAD_CHECK_SLEEP
	if psexist -S $INSTNAME | grep -q "instance: $INSTNAME"; then
	    logerr 2 "ERROR: eXist instance \"${INSTNAME}\" still running after stop command"
	fi
    else
	logmsg "eXist instance \"${INSTNAME}\" not running"
    fi
}
