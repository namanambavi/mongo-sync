#!/bin/bash

set -e           # exit on error
set -o pipefail  # trace ERR through pipes
set -o errtrace  # trace ERR through 'time command' and other functions
set -o errexit   # exit the script if any statement returns a non-true return value

function cleanup {
    echo "Cleaning up..."
    if [ -z ${TMPDIR+x} ] ; then
        echo -n
    else
        rm -rf $TMPDIR
        unset TMPDIR
    fi
    unset LOCAL_CREDENTIALS
    unset REMOTE_CREDENTIALS
}

function error {
    local parent_lineno="$1"
    local message="$2"
    local code="${3:-1}"
    if [[ -n "$message" ]] ; then
        echo "Error on or near line ${parent_lineno}: ${message}; exiting with status ${code}"
    else
        echo "Error on or near line ${parent_lineno}; exiting with status ${code}"
    fi
    cleanup
    exit "${code}"
}
trap 'error ${LINENO}' ERR

function config_not_found {
    echo "failed: 'config.yml' not found, it needs to be in the same dir"
    echo "aborting..."
    echo ""
    exit
}

function parse_yaml {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  "$1" |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
}

function get_script_dir {
    pushd . > /dev/null
    local SCRIPT_PATH="${BASH_SOURCE[0]}"

    if ([ -h "${SCRIPT_PATH}" ]) then
      while ([ -h "${SCRIPT_PATH}" ]) do cd `dirname "$SCRIPT_PATH"`; SCRIPT_PATH=`readlink "${SCRIPT_PATH}"`; done
    fi

    cd `dirname ${SCRIPT_PATH}` > /dev/null
    local SCRIPT_PATH=`pwd`;
    popd  > /dev/null

    echo $SCRIPT_PATH
}

function get_confirmation() {
    read -p "Are you sure you want to pull from remote DB? Enter 'yes': " mongo_confr

    case $mongo_confr in
        [yY][Ee][Ss] )  ;;
        *) echo "Incorrect input, aborting..."; exit;;
    esac
}

function load_configs {
    echo "Loading configuration..."
    DIR=$(get_script_dir)
    local FILE="$DIR/config.yml"

    if [ -f "$FILE" ]; then
       eval $(parse_yaml "$FILE")
       echo "Configuration loaded successfully!"
       echo
    else
       config_not_found
    fi

    LOCAL_CREDENTIALS=""
    if [[ ! -z $local_access_username ]] ; then
        LOCAL_CREDENTIALS="-u $local_access_username -p $local_access_password"
    fi

    REMOTE_CREDENTIALS=""
    if [[ ! -z $remote_access_username ]] ; then
        REMOTE_CREDENTIALS="-u $remote_access_username -p $remote_access_password"
    fi

    TMPDIR=/tmp/"$local_db"/dump
}

function banner {
    echo "MongoDB Sync Tool"
    echo "----------------"
}

## MAIN
## ====

banner
get_confirmation
load_configs

echo "Dumping Remote DB to $TMPDIR... "
mongodump \
    -h "$remote_host_url":"$remote_host_port" \
    -d "$remote_db" \
    $REMOTE_CREDENTIALS \
    --authenticationDatabase admin \
    -o "$TMPDIR" > /dev/null
echo "Remote database dump completed successfully!"
echo

echo "Overwriting Local DB with Dump... "
mongorestore \
    --port "$local_host_port" \
    -d "$local_db" \
    $LOCAL_CREDENTIALS \
    "$TMPDIR"/"$remote_db" \
    --drop > /dev/null
echo "Local database restored successfully!"
echo

cleanup
echo "Done!"
echo