#!/bin/sh
#
# Description: $ Common funcs that are likely to be used in various of places.
#
# Authors: cyng93
#
# Contact: cyng93@gmail.com
#
# Date: $Date: 2017/11/09 12:00:00 $
# Version: $Revision: 1.1 $
#
# History:
#
# $Log: CommonFunc.sh,v $
# Revision 1.1  2017/11/09  12:00:00  cyng93
# Add MissingArg, CheckFileExist, CheckDirExist
#
# Revision 1.0  2017/11/08  21:39:00  cyng93
# Add PrintMsg which support printing based on different log level


# ---------- DEFAULT ARGS
LOG_LEVEL=10        # By default we print out msg with log_level < 10 (info)
EXIT_ON_ERROR=1     # Shall we abort program after printing error msg

DEFAULT_MSG_LEVEL=10
DEFAULT_MSG_LEVEL_STR="INFO"


# ---------- FUNCTIONS

#
# PrintMsg ( _msg, _msg_lvl=DEFAULT_MSG_LEVEL )
#
#   Print out only msg with `_msg_lvl` < `LOG_LEVEL`.
#   If `EXIT_ON_ERROR` flag is set (which happened to be set by default),
#   abort program after printing msg where `_msg_lvl` is ERROR
#
#   log level:
#      0 - ERROR
#      5 - WARNING
#     10 - INFO
#     15 - DEBUG
#
function PrintMsg
{
    local _msg
    local _lvl
    local _msg_lvl
    local _msg_lvl_str

    [ "$1" ] && _msg=$1 || return 0
    [ "$2" ] && _lvl=$2 \
        || { _msg_lvl=$DEFAULT_MSG_LEVEL; _msg_lvl_str=$DEFAULT_MSG_LEVEL_STR; }

    case $_lvl in
        15 | "D" | "DEBUG" )
            _msg_lvl=15
            _msg_lvl_str="DEBUG"
            ;;
        10 | "I" | "INFO" )
            _msg_lvl=10
            _msg_lvl_str="INFO"
            ;;
        5 | "W" | "wARNING" )
            _msg_lvl=5
            _msg_lvl_str="WARNING"
            ;;
        0 | "E" | "ERROR" )
            _msg_lvl=0
            _msg_lvl_str="ERROR"
            ;;
    esac

    if [ "$_msg_lvl" -le "$LOG_LEVEL" ]; then
        echo -e "[$_msg_lvl_str]\t${1}"
        if [ $EXIT_ON_ERROR -eq 1 ]; then
            [ 0 -eq $_msg_lvl ] && exit 1 || true
        fi
    fi
}


# MissingArg ( _func, _arg, _lineno )
#
#   Print missing argument message, then abort the program.
#
function MissingArg
{
    local _arg
    local _func

    [ "$1" ] \
        && _func=$1    || PrintMsg "\`MissingArg\` missing arg \`_func\`" "E"
    [ "$2" ] \
        && _arg=$2     || PrintMsg "\`MissingArg\` missing arg \`_arg\`" "E"

    PrintMsg "$_func missing arg \`$_arg\`" "E"
}


# CheckPathExist ( _path, _type )
#   return 1 if `_path` exist as file type `_type`, 0 otherwise
#
function CheckPathExist
{
    local _path
    local _type
    local _ret

    [ "$1" ] && _path=$1 || MissingArg "${FUNCNAME[0]}:$LINENO" "_path"
    [ "$2" ] && _type=$2 || MissingArg "${FUNCNAME[0]}:$LINENO" "_type"

    case "$_type" in
        "FILE" )
            [ -f "$_path" ] && _ret=1 || _ret=0
            ;;
        "DIR" )
            [ -d "$_path" ] && _ret=1 || _ret=0
            ;;
        *)
            PrintMsg "\`${FUNCNAME[0]}:$LINENO\` invalid type \`$_path\`" "E"
            ;;
    esac

    return $_ret
}


# CheckFileExist
#   return 1 if `_file` exist, 0 otherwise
#
function CheckFileExist
{
    local _file
    local _ret

    [ "$1" ] && _file=$1 || MissingArg "${FUNCNAME[0]}:$LINENO" "_file"

    CheckPathExist "$_file" "FILE" \
        && _ret=1 || _ret=0

    return $_ret
}


# CheckDirExist
#   return 1 if `_file` exist, 0 otherwise
#
function CheckDirExist
{
    local _dir
    local _ret

    [ "$1" ] && _dir=$1 || MissingArg "${FUNCNAME[0]}:$LINENO" "_dir"

    CheckPathExist "$_dir" "DIR" \
        && _ret=1 || _ret=0

    return $_ret
}
