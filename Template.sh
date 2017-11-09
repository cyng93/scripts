#!/bin/sh
#
# Description: $ This script serves as a template to start writing new script
#
# Authors: cyng93
#
# Contact: cyng93@gmail.com
#
# Date: $Date: 2017/01/01 00:00:00 $
# Version: $Revision: 0.1 $
#
# History:
#
# $Log: Template.sh $
# Revision 0.1  2017/01/01  00:00:00  cyng93
# Some Changelog about this revision


# ---------- SOURCE , INCLUDE
url="https://raw.githubusercontent.com/cyng93/scripts/master/CommonFunc.sh"
curl -s $url > /tmp/.CommonFunc.sh && true \
    || { echo "[ERROR] Fail to download CommonFunc. Aborting."; exit 1; }
source /tmp/.CommonFunc.sh


# ---------- DEFAULT_ARGS
LOG_LEVEL=10


# ---------- DEDICATED FUNCTIONS
#
# Usage ( [_exit_val] )
#
#   Abort program with exit value = `_exit_val` after printing usage,
#   if `_exit_val` was provided.
#
function Usage
{
    local _prog=$(basename $0)

    echo "Usage: $_prog [option]..."
    echo "option:"
    echo "  --help      : Print this help message"
    echo "  --version   : Print current version"
    echo "  --log-level <log_level>"
    echo "      0 : ERROR"
    echo "      5 : WARNING"
    echo "      10: INFO (default)"
    echo "      15: DEBUG"
    [ $1 ] && exit $1 || true
}


# ---------- GENERAL FUNCTIONS
function CheckParams
{
    while [ "$1" != "" ]; do
        case $1 in
        -h | --help)
            Usage 0
            ;;
        -v | --version)
            grep "\$Revision" $0 | head -n 1 | awk '{print "version", $4}'
            exit 0
            ;;
        --log-level)
            [ "$2" = "" ] && Usage 1 || LOG_LEVEL=$2
            shift
            ;;
        *)
            Usage 1
        esac
        shift
    done
}


# ---------- ENTRY POINT
[ ! $@ ] && Usage 1 || CheckParams $@
