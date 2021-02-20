#!/bin/bash

REGIONS=( $1 )
REGIONS_IP_NUM=( $2 )
MASTER_REGION=${REGIONS[$3]}
MASTER_IP_NUM=${REGIONS_IP_NUM[$3]}

EXPORT_CF_VAR_VPC='MariadbVmVPC'
EXPORT_CF_VAR_ROUTE_TABLE='MariadbVmRouteTable'

#################################
## Running install stack
#################################

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

## run all instance an all europe regions
for i in "${!REGIONS[@]}";
do 
    AMIID=$(aws ec2 describe-images \
      --owners $ACCOUNT_ID \
      --query "Images[*].ImageId" \
      --region ${REGIONS[$i]} \
      --output text)

    aws cloudformation create-stack --stack-name mariadb \
        --template-url https://s3-eu-west-1.amazonaws.com/$BUCKET_NAME${REGIONS_IP_NUM[$i]}/aws-mariadb.yml \
        --parameters ParameterKey=KeyName,ParameterValue=mariadb ParameterKey=AMIID,ParameterValue=$AMIID ParameterKey=MariaNumber,ParameterValue=${REGIONS_IP_NUM[$i]} \
        --region ${REGIONS[$i]}
done

## wait for all stack to be finished
for i in "${REGIONS[@]}";
do
    aws cloudformation wait stack-create-complete --stack-name mariadb --region $i
done

#################################
## Connection between instances
#################################
get_export_variable()
{
        aws cloudformation list-exports \
                --query "Exports[?Name == '$2'].Value" \
                --output text \
                --region $1

}

MASTER_VPC=$(get_export_variable $MASTER_REGION $EXPORT_CF_VAR_VPC)
MASTER_ROUTE_TABLE=$(get_export_variable $MASTER_REGION $EXPORT_CF_VAR_ROUTE_TABLE)

#for i in "${REGIONS[@]}";
for i in "${!REGIONS[@]}";
do
        if [ "${REGIONS[$i]}" != "$MASTER_REGION" ]; then
                #################################
                ## VPC Peering Connection
                #################################
                VPC_PEERING_ID=$(aws ec2 create-vpc-peering-connection \
                        --vpc-id $(get_export_variable ${REGIONS[$i]} $EXPORT_CF_VAR_VPC) \
                        --peer-vpc-id $MASTER_VPC  \
                        --peer-region $MASTER_REGION \
                        --output text \
                        --query "VpcPeeringConnection.{VpcPeeringConnectionId:VpcPeeringConnectionId}" \
                        --region ${REGIONS[$i]})
		echo $VPC_PEERING_ID

                STEP_VPC_PEERING=$(aws ec2 accept-vpc-peering-connection \
                        --vpc-peering-connection-id $VPC_PEERING_ID \
                        --region $MASTER_REGION)
		echo $STEP_VPC_PEERING

                #################################
                ## Create Route in RouteTable
                #################################
                STEP_ROUTE_MASTER=$(aws ec2 create-route \
                        --route-table-id $MASTER_ROUTE_TABLE \
                        --destination-cidr-block 10.10.${REGIONS_IP_NUM[$i]}.1${REGIONS_IP_NUM[$i]}/32 \
                        --vpc-peering-connection-id $VPC_PEERING_ID \
                        --region $MASTER_REGION)
		echo $STEP_ROUTE_MASTER

                STEP_ROUTE_SLAVE=$(aws ec2 create-route \
                        --route-table-id $(get_export_variable ${REGIONS[$i]} $EXPORT_CF_VAR_ROUTE_TABLE) \
                        --destination-cidr-block 10.10.$MASTER_IP_NUM.1$MASTER_IP_NUM/32 \
                        --vpc-peering-connection-id $VPC_PEERING_ID \
                        --region ${REGIONS[$i]})
		echo $STEP_ROUTE_SLAVE
        fi
done
