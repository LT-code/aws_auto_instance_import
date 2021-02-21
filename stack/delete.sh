#!/bin/bash

. $(echo $1)

LIST_VPC_PEERING_CONNECTIONS=( $(aws ec2 describe-vpc-peering-connections \
        --query "VpcPeeringConnections[*].VpcPeeringConnectionId" \
        --region $MASTER_REGION \
        --output text) )

for i in "${LIST_VPC_PEERING_CONNECTIONS[@]}";
do
        aws ec2 delete-vpc-peering-connection \
                --vpc-peering-connection-id $i \
                --region $MASTER_REGION
done


## run all instance an all europe regions
for i in "${REGIONS[@]}";
do
  aws cloudformation delete-stack \
    --stack-name $STASK_NAME \
    --region $i
done

## wait for all stack to be finished
for i in "${REGIONS[@]}";
do
        aws cloudformation wait stack-delete-complete \
                --stack-name $STASK_NAME \
                --region $i

        VOLUMES=( $(aws ec2 describe-volumes \
                --query "Volumes[?State == 'available'].VolumeId" \
                --output text \
                --region $i) )

        for j in "${VOLUMES[@]}";
        do
                aws ec2 delete-volume \
                        --volume-id $j \
                        --region $i
        done
done
