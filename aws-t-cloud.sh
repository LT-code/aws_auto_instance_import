#!/bin/bash
#PACKAGE_TO_INSTALL=jq mariadb-client awcli

REGIONS='eu-west-1 eu-west-2 eu-west-3'
REGIONS_IP_NUM='11 12 13'
REGIONS_AMI_IDS='ami-0bd0d585e48c2c0aa ami-0b45dddb137be75a6 ami-028871628cff8310e'
MASTER_NUM=0

## Test
MASTER_PASSWORD="nXr^3t7Ck%XLD.&*"
SLAVE_PASSWORD="MotDePasse"


 case "$1" in
 "import")
     ./import/import.sh 
     ;;
 "create")
     ./stack/create.sh \
       "$REGIONS" \
       "$REGIONS_IP_NUM" \
       "$MASTER_NUM" \
       "$REGIONS_AMI_IDS" 
     ;;
 "test")
     ./stack/test.sh \
       "$REGIONS" \
       "$MASTER_NUM" \
       "$MASTER_PASSWORD" \
       "$SLAVE_PASSWORD"
     ;;
 "delete")
     ./stack/delete.sh \
       "$REGIONS" \
       "$NASTER_NUM"
     ;;
 *)
     echo "Parameters:
     import
     create
     test
     delete"
     ;;
 esac
