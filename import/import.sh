#!/bin/bash

. $(echo $1)

./import/create-role-policy.sh $1

################################
# allow vm import
################################
aws iam create-role --role-name vmimport --assume-role-policy-document "file://import/trust-policy.json"
aws iam put-role-policy --role-name vmimport --policy-name vmimport --policy-document "file://import/role-policy.json"

################################
# import all images
################################
declare -a IMPORT_TASK_ID

for i in "${!REGIONS[@]}";
do
  IP=${REGIONS_IP_NUM[$i]}

  # get ami
  ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
  AMIID=$(aws ec2 describe-images \
    --owners $ACCOUNT_ID \
    --query "Images[*].ImageId" \
    --region ${REGIONS[$i]} \
    --output text)

  if [ "$AMIID" = "" ]; then
    sed -i "/S3Bucket/c\   \"S3Bucket\" : \"$BUCKET_NAME$IP\"," "import/vm-1$IP-import.json"

	  echo "############## vm 1$IP"
	  #qemu-img convert /mnt/isofiles/briks/images/${IMAGE_NAME[$i]}/vm-${IMAGE_NAME[$i]}-disk-0.qcow2 ./${IMAGE_NAME[$i]}.raw

    # create s3 bucket
	  aws s3 mb \
      s3://$BUCKET_NAME$IP \
      --region ${REGIONS[$i]}

    if [ "$MASTER_REGION" = "${REGIONS[$i]}" ]; then
      aws s3 cp \
        CloudFormation/aws-mariadb.yml \
        s3://$BUCKET_NAME$MASTER_IP_NUM/aws-mariadb.yml
    fi

    # copy vm to s3 bucket
	  aws s3 cp \
      ./${IMAGE_NAME[$i]}.raw \
      s3://$BUCKET_NAME$IP/${IMAGE_NAME[$i]}.raw

    IMPORT_TASK_ID+=($(aws ec2 import-image \
      --region ${REGIONS[$i]} \
      --description "Mariadb 1$IP" \
      --disk-containers "file://import/vm-1$IP-import.json"))
  fi
done

# monitoring import
#aws ec2 describe-import-image-tasks --import-task-ids import-ami-1234567890abcdef0
AMIID=""
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
for i in "${!REGIONS[@]}";
do
	while [ "$AMIID" = "" ]
	do
	  AMIID=$(aws ec2 describe-images \
	    --owners $ACCOUNT_ID \
	    --query "Images[*].ImageId" \
	    --region ${REGIONS[$i]} \
	    --output text)
	done
done
