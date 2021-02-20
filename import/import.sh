#!/bin/bash


aws iam create-role --role-name vmimport --assume-role-policy-document "file://import/trust-policy.json"

aws iam put-role-policy --role-name vmimport --policy-name vmimport --policy-document "file://import/role-policy.json"

for i in `seq 2 3`;
do
	echo "############## vm 11$i"
	qemu-img convert /mnt/isofiles/briks/images/11$i/vm-11$i-disk-0.qcow2 ./11$i.raw
	aws s3 mb \
    s3://vm-import-images-epitech-tcloud901-vm11$i \
    --region eu-west-$i

	aws s3 cp \
    ./11$i.raw \
    s3://vm-import-images-epitech-tcloud901-vm11$i/11$i.raw

	aws ec2 import-image \
    --region eu-west-$i \
    --description "Mariadb $i" \
    --disk-containers "file://import/vm-11$i-import.json"
done

aws s3 cp \
  CloudFormation/aws-mariadb.yml \
  s3://vm-import-images-epitech-tcloud901-vm11$i/aws-mariadb.yml

# monitoring import
#aws ec2 describe-import-image-tasks --import-task-ids import-ami-1234567890abcdef0
