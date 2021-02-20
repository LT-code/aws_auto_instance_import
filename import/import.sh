#!/bin/bash

REGIONS=( $1 )
REGIONS_IP_NUM=( $2 )
BUCKET_NAME=$3

./import/create-role-policy.sh \
  "$REGIONS_IP_NUM" \
  "$BUCKET_NAME"

aws iam create-role --role-name vmimport --assume-role-policy-document "file://import/trust-policy.json"
aws iam put-role-policy --role-name vmimport --policy-name vmimport --policy-document "file://import/role-policy.json"

for i in "${!REGIONS[@]}";
do
  IP=${REGIONS_IP_NUM[$i]}

  sed -i "/S3Bucket/c\   \"S3Bucket\" : \"$BUCKET_NAME$IP\"," "import/vm-1$IP-import.json"


	echo "############## vm 1$IP"
	qemu-img convert /mnt/isofiles/briks/images/1$IP/vm-1$IP-disk-0.qcow2 ./1$IP.raw

	aws s3 mb \
    s3://vm-import-images-epitech-tcloud901-vm1$IP \
    --region ${REGIONS[$i]}

	aws s3 cp \
    ./1$i.raw \
    s3://$BUCKET_NAME$i/1$i.raw

	aws ec2 import-image \
    --region ${REGIONS[$i]} \
    --description "Mariadb 1$IP" \
    --disk-containers "file://import/vm-1$IP-import.json"
done

aws s3 cp \
  CloudFormation/aws-mariadb.yml \
  s3://$BUCKET_NAME$i/aws-mariadb.yml

# monitoring import
#aws ec2 describe-import-image-tasks --import-task-ids import-ami-1234567890abcdef0
