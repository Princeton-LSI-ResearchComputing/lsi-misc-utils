#!/usr/bin/env bash

VERBOSE=0
LDAP_HOST="pu.win.princeton.edu"
LDAP_PORT=389
LDAP_BASE_DN="dc=pu,dc=win,dc=princeton,dc=edu"
LDAP_BIND_DN="$(whoami)@princeton.edu"

function usage {
    echo "Usage: $(basename "$0") [options] userid_list.txt"
    echo ""
    echo "    Options:"
    echo "        -h      LDAP host (default: $LDAP_HOST)"
    echo "        -p      LDAP host port (default: $LDAP_PORT)"
    echo "        -b      LDAP Base DN (default: $LDAP_BASE_DN)"
    echo "        -D      LDAP Bind DN (default: $LDAP_BIND_DN)"
    echo "        -v      Verbose, output results of ldapsearch"
    echo ""
}

if [ $# -eq "0" ]; then
    usage
    exit
fi


while getopts ":vh:p:b:D:" opt; do
    case $opt in
        h) LDAP_HOST=$OPTARG;;
        p) LDAP_PORT=$OPTARG;;
        b) LDAP_BASE_DN=$OPTARG;;
        D) LDAP_BIND_DN=$OPTARG;;
        v) VERBOSE=1;;
        \?) echo "Invalid option: -$OPTARG" >&2; usage; exit 1 ;;
    esac
done

shift $((OPTIND - 1))

FILE=$1

echo "Enter password for $LDAP_BIND_DN (will be used on commandline)"
read -r -s PASSWORD

while read -r line; do
        echo -ne "$line - "
        if [ "$line" == "(null)" ]
        then
            echo "SKIPPED"
            continue
        fi
        out=$(ldapsearch -x -h "$LDAP_HOST" -p "$LDAP_PORT" -b "$LDAP_BASE_DN" -D "$LDAP_BIND_DN" -w "$PASSWORD" -o ldif-wrap=no "(uid=$line)" "db")
        ret=$?
        if [[ $ret -ne 0 ]]; then
            echo "ERROR: Exit code '$ret' executing ldapsearch"
            usage
            exit
        else  
            if grep -q "numEntries: 1" <<<"$out"; then
                if grep -q "OU=DisabledAccounts" <<<"$out"; then
                    echo "DISABLED"
                else
                    echo "FOUND"
                fi
            else
                    echo "NOT FOUND"
            fi 
            if [[ $VERBOSE == 1 ]]; then
                printf "%s" "$out"
                echo ""
            fi
        fi
done < "$FILE"
