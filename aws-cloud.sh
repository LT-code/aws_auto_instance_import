#!/bin/bash
#PACKAGE_TO_INSTALL=jq mariadb-client awcli

REGIONS='eu-west-1 eu-west-2 eu-west-3'
REGIONS_IP_NUM='11 12 13'
REGIONS_AMI_IDS='ami-1 ami-2 ami-3'
MASTER_NUM=0

## Test
MASTER_PASSWORD="nXr^3t7Ck%XLD.&*"
SLAVE_PASSWORD="MotDePasse"


#./import/import.sh 

./stack/create.sh \
  $REGIONS \
  $REGIONS_IP_NUM \
  $MASTER_NUM \
  $REGIONS_AMI_IDS

#./stack/delete.sh \
#  $REGIONS \
#  $NASTER_NUM
#
#./stack/test.sh \
#  $REGIONS \
#  $MASTER_NUM \
#  $MASTER_PASSWORD \
#  $SLAVE_PASSWORD
