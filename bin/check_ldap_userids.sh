#!/usr/bin/env bash

VERBOSE=0
LDAP_HOST="ldap.princeton.edu"
LDAP_PORT=389
LDAP_BASE_DN="o=Princeton University,c=US"
SIMPLE_AUTHENTICATION=""
START_TLS="-ZZ"

function usage {
    echo "Usage: `basename $0` [options] userid_list.txt"
    echo ""
    echo "    Options:"
    echo "        -h      LDAP host (default: $LDAP_HOST)"
    echo "        -p      LDAP host port (default: $LDAP_PORT)"
    echo "        -b      LDAP Base DN (default: $LDAP_BASE_DN)"
    echo "        -v      Verbose, output results of ldapsearch"
    echo "        -x      Simple authentication"
    echo "        -z      Do not use StartTLS (Default is to require successful response [-ZZ])"
    echo ""
}

if [ $# -eq "0" ]; then
    usage
    exit
fi


while getopts ":vxzh:p:b:" opt; do
    case $opt in
        h) LDAP_HOST=$OPTARG;;
        p) LDAP_PORT=$OPTARG;;
        b) LDAP_BASE_DN=$OPTARG;;
        v) VERBOSE=1;;
        x) SIMPLE_AUTHENTICATION="-x";;
        z) START_TLS="";;
        \?) echo "Invalid option: -$OPTARG" >&2; usage; exit 1 ;;
    esac
done

shift $(($OPTIND - 1))

FILE=$1
while read line; do
        echo -ne "$line - "
        out=$(ldapsearch $START_TLS $SIMPLE_AUTHENTICATION -h $LDAP_HOST -p $LDAP_PORT -b "$LDAP_BASE_DN" "(uid=$line)")
        ret=$?
        if [[ $ret -ne 0 ]]; then
            echo "ERROR: Exit code '$ret' executing ldapsearch"
            usage
            exit
        else  
            if grep -q "numEntries: 1" <<<$out; then
            #if [[ $out != "" ]]; then
                    echo "FOUND"
            else
                    echo "NOT FOUND"
            fi 
            if [[ $VERBOSE == 1 ]]; then
                printf "$out"
                echo ""
            fi
        fi
done < $FILE
