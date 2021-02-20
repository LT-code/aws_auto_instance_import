#!/bin/bash

REGIONS=( "eu-west-1" "eu-west-2" "eu-west-3" )
REGIONS_IP_NUM=( "11" "12" "13" )
MASTER_NUM=0

## Test
MASTER_PASSWORD="nXr^3t7Ck%XLD.&*"
SLAVE_PASSWORD="MotDePasse"


./import/import.sh 

./stack/create.sh \
  $REGIONS \
  $REGIONS_IP_NUM \
  $MASTER_NUM 

./stack/delete.sh \
  $REGIONS \
  $NASTER_NUM

./stack/test.sh \
  $REGIONS \
  $MASTER_NUM \
  $MASTER_PASSWORD \
  $SLAVE_PASSWORD
