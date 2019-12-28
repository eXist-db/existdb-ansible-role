
logmsg() {
    _msg=$*
    echo $_msg
    [ -n "$LOGFILE" ] && echo $_msg >>$LOGFILE
    [ -n "$SYSLOG" ]  && logger -t exist-filebased-backup $_msg
}

logerr() {
    _excode=$1
    shift
    _msg=$*
    echo $_msg >&2
    [ -n "$LOGFILE" ] && echo $_msg >>$LOGFILE
    [ -n "$SYSLOG"  ] && logger -t exist-filebased-backup -p error $_msg
    echo "exiting, logfile $LOGFILE" >&2
    exit $_excode
}
