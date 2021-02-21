#!/bin/bash

######################################################
# Package management
######################################################
PACKAGE_NAME=( "mysql" "aws" )
PACKAGE_REQUIRED=( "mariadb-cient" "awscli" )

for var in ${!PACKAGE_NAME[@]}; do
  if ! which ${PACKAGE_NAME[$var]} &> /dev/null; then
      echo "${PACKAGE_REQUIRED[$var]} is not installed"
      exit -1
  fi
done

######################################################
# Parameters
######################################################
case "$1" in
 "import")
     RUN="./import/import.sh $2"
     ;;
 "create")
     RUN="./stack/create.sh $2"
     ;;
 "test")
     RUN="./stack/test.sh $2"
     ;;
 "delete")
     RUN="./stack/delete.sh $2"
     ;;
 *)
     echo "Parameters:
     - import
     - create
     - test
     - delete"
     exit -1
     ;;
 esac


if [ ! -f "$2" ]; then
    if [ "$2" = "" ]; then
      echo "Configuration filename is require."
    else
      echo "'$2' does not exist."
    fi
    exit -1
fi

sh -c "$RUN"
