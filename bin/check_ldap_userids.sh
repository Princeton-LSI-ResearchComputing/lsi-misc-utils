#!/usr/bin/env bash

VERBOSE=0
LDAP_HOST="ldap.princeton.edu"
LDAP_PORT=389
LDAP_BASE_DN="o=Princeton University,c=US"

function usage {
    echo "Usage: `basename $0` [options] userid_list.txt"
    echo ""
    echo "    Options:"
    echo "        -h      LDAP host (default: $LDAP_HOST)"
    echo "        -p      LDAP host port (default: $LDAP_PORT)"
    echo "        -b      LDAP Base DN (default: $LDAP_BASE_DN)"
    echo "        -v      Verbose, output results of ldapsearch"
    echo ""
}

if [ $# -eq "0" ]; then
    usage
    exit
fi


while getopts ":vh:p:b:" opt; do
    case $opt in
        h) LDAP_HOST=$OPTARG;;
        p) LDAP_PORT=$OPTARG;;
        b) LDAP_BASE_DN=$OPTARG;;
        v) VERBOSE=1;;
        \?) echo "Invalid option: -$OPTARG" >&2 ;;
    esac
done

shift $(($OPTIND - 1))

FILE=$1
while read line; do
        echo -ne "$line - "
        out=$(ldapsearch -h $LDAP_HOST -p $LDAP_PORT -b "$LDAP_BASE_DN" "(uid=$line)")
        ret=$?
        if [[ $ret -ne 0 ]]; then
            echo "ERROR: Exit code '$ret' executing ldapsearch"
            usage
            exit
        else  
            #if grep -q "numEntries: 1" <<<$out; then
            if [[ $out != "" ]]; then
                    echo "FOUND"
            else
                    echo "NOT FOUND"
            fi 
            if [[ $VERBOSE == 1 ]]; then
                echo $out
                echo ""
            fi
        fi
done < $FILE
