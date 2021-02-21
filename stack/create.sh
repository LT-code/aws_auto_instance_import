#!/bin/bash 

. $(echo $1) 

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

    KEY_NAME=mariadb-${REGIONS_IP_NUM[$i]}
    aws ec2 create-key-pair \
      --key-name $KEY_NAME \
      --query "KeyMaterial" \
      --region ${REGIONS[$i]} \
      --output text > $KEY_NAME.pem

    aws cloudformation create-stack --stack-name $STACK_NAME${REGIONS_IP_NUM[$i]} \
        --template-url https://s3-$MASTER_REGION.amazonaws.com/$BUCKET_NAME$MASTER_IP_NUM/aws-mariadb.yml \
        --parameters ParameterKey=KeyName,ParameterValue=$KEY_NAME ParameterKey=AMIID,ParameterValue=$AMIID ParameterKey=MariaNumber,ParameterValue=${REGIONS_IP_NUM[$i]} ParameterKey=MasterRegion,ParameterValue=$MASTER_REGION \
        --region ${REGIONS[$i]}
        #--template-url https://raw.githubusercontent.com/LT-code/aws_auto_instance_import/main/CloudFormation/aws-mariadb.yml
done

## wait for all stack to be finished
for i in "${!REGIONS[@]}";
do
    aws cloudformation wait stack-create-complete \
      --stack-name $STACK_NAME${REGIONS_IP_NUM[$i]} \
      --region ${REGIONS[$i]}
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

MASTER_VPC=$(get_export_variable $MASTER_REGION $EXPORT_CF_VAR_VPC$MASTER_IP_NUM)
MASTER_ROUTE_TABLE=$(get_export_variable $MASTER_REGION $EXPORT_CF_VAR_ROUTE_TABLE$MASTER_IP_NUM)

for i in "${!REGIONS[@]}";
do
  if [ "${REGIONS[$i]}" != "$MASTER_REGION" ]; then
    #################################
    ## VPC Peering Connection
    #################################
    VPC_PEERING_ID=$(aws ec2 create-vpc-peering-connection \
            --vpc-id $(get_export_variable ${REGIONS[$i]} $EXPORT_CF_VAR_VPC${REGIONS_IP_NUM[$i]}) \
            --peer-vpc-id $MASTER_VPC  \
            --peer-region $MASTER_REGION \
            --output text \
            --query "VpcPeeringConnection.{VpcPeeringConnectionId:VpcPeeringConnectionId}" \
            --region ${REGIONS[$i]})

		echo $VPC_PEERING_ID
    sleep 2

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
            --route-table-id $(get_export_variable ${REGIONS[$i]} $EXPORT_CF_VAR_ROUTE_TABLE${REGIONS_IP_NUM[$i]}) \
            --destination-cidr-block 10.10.$MASTER_IP_NUM.1$MASTER_IP_NUM/32 \
            --vpc-peering-connection-id $VPC_PEERING_ID \
            --region ${REGIONS[$i]})
		echo $STEP_ROUTE_SLAVE
  fi
done
