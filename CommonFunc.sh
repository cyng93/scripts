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
#$Func
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


#$Func
# MissingArg ( _func, _arg )
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


#$Func
# CheckPathExist ( _path, _type )
#
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


#$Func
# CheckFileExist ( _file )
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


#$Func
# CheckDirExist ( _dir )
#   return 1 if `_dir` exist, 0 otherwise
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


#$Func
# ListFunc ()
#
#   List out all func-proto in the next line to "$Func"
#
function ListFunc
{
    local _prog=$(basename $0)
    echo ""
    echo "$_prog's functions:"
    echo ""

    # grep "\$FUNC" $0 | head -n -1 | awk '{$1=" -"}1'      # $FUNC is sameline
    cat $0 | awk '/^#\$Func/{getline; print " -", substr($0,3)}'
    echo ""
}


# ----------- DEDICATED FUNC
function Usage
{
    local _prog=$(basename $0)
    local url="https://raw.githubusercontent.com/cyng93/scripts/master/CommonFunc.sh"

    echo ""
    echo " cyng93's CommonFunc.sh"
    echo " ======================"
    echo ""
    echo "  Usage: $_prog [option]..."
    echo "  option:"
    echo "      --help      : print this usage"
    echo "      --version   : print current version"
    echo "      --list-all  : print all available functions"
    echo ""
    echo "  Github: https://github.com/cyng93/scripts/"
    echo ""
    echo "  To use it, append following lines in top of your scripts:"
    echo '  ```'
    echo '  url="https://raw.githubusercontent.com/cyng93/scripts/master/CommonFunc.sh"'
    echo '  if [ ! $(cat "/tmp/.CommonFunc.sh" > /dev/null 2>&1) ]; then'
    echo '      curl -s $url > /tmp/.CommonFunc.sh && true \'
    echo '          || { echo "[ERROR] Fail to download CommonFunc. Aborting."; exit 1; }'
    echo "  fi"
    echo "  source /tmp/.CommonFunc.sh"
    echo '  ```'
    echo ""

    [ "$1" ] && exit $1 || true
}


# ----------- ENTRY POINT
case $1 in
    "-h" | "--help" )
        Usage 0
        ;;
    "-l" | "--list-all" )
        ListFunc
        ;;
    "-v" | "--version" )
        grep "\$Revision:" $0 | head -n 1 | awk '{print "version", $4}'
        ;;
esac
