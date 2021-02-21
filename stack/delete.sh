#!/bin/bash

. $(echo $1)

##############################
# deleting peering connections
##############################
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


##############################
# delete all stack
##############################
for i in "${!REGIONS[@]}";
do
  aws cloudformation delete-stack \
    --stack-name $STACK_NAME${REGIONS_IP_NUM[$i]} \
    --region ${REGIONS[$i]}
done

##############################
# wait for all stack to be finished
##############################
for i in "${!REGIONS[@]}";
do
        aws cloudformation wait stack-delete-complete \
                --stack-name $STACK_NAME${REGIONS_IP_NUM[$i]} \
                --region ${REGIONS[$i]}

        ##############################
        # deleting volumes
        ##############################
        VOLUMES=( $(aws ec2 describe-volumes \
                --query "Volumes[?State == 'available'].VolumeId" \
                --output text \
                --region ${REGIONS[$i]}) )

        for j in "${VOLUMES[@]}";
        do
                aws ec2 delete-volume \
                        --volume-id $j \
                        --region ${REGIONS[$i]}
        done
done
