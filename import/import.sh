#!/bin/bash

. $(echo $1)

./import/create-role-policy.sh $1

aws iam create-role --role-name vmimport --assume-role-policy-document "file://import/trust-policy.json"
aws iam put-role-policy --role-name vmimport --policy-name vmimport --policy-document "file://import/role-policy.json"


for i in "${!REGIONS[@]}";
do
  IP=${REGIONS_IP_NUM[$i]}
  echo $IP

  sed -i "/S3Bucket/c\   \"S3Bucket\" : \"$BUCKET_NAME$IP\"," "import/vm-1$IP-import.json"


	echo "############## vm 1$IP"
	#qemu-img convert /mnt/isofiles/briks/images/1$IP/vm-1$IP-disk-0.qcow2 ./1$IP.raw

	aws s3 mb \
    s3://$BUCKET_NAME$IP \
    --region ${REGIONS[$i]}

  if [ "$MASTER_REGION" = "${REGIONS[$i]}" ]; then
    aws s3 cp \
      CloudFormation/aws-mariadb.yml \
      s3://$BUCKET_NAME$MASTER_IP_NUM/aws-mariadb.yml
  fi

	aws s3 cp \
    ./1$IP.raw \
    s3://$BUCKET_NAME$IP/1$IP.raw

	aws ec2 import-image \
    --region ${REGIONS[$i]} \
    --description "Mariadb 1$IP" \
    --disk-containers "file://import/vm-1$IP-import.json"
done


# monitoring import
#aws ec2 describe-import-image-tasks --import-task-ids import-ami-1234567890abcdef0
