#!/bin/bash
#PACKAGE_TO_INSTALL=jq mariadb-client awcli

REGIONS='eu-west-1 eu-west-2 eu-west-3'
REGIONS_IP_NUM='11 12 13'
MASTER_NUM=0

## S3
BUCKET_NAME=vm-import-images-epitech-tcloud901-presentation-vm1

## Test
MASTER_PASSWORD="nXr^3t7Ck%XLD.&*"
SLAVE_PASSWORD="MotDePasse"


 case "$1" in
 "import")
     ./import/import.sh 
       "$REGIONS" \
       "$REGIONS_IP_NUM" \
       "$BUCKET_NAME"
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
     - import
     - create
     - test
     - delete"
     ;;
 esac
