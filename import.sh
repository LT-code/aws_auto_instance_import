#!/bin/bash


#aws iam create-role --role-name vmimport --assume-role-policy-document "file://import/trust-policy.json"

#aws iam put-role-policy --role-name vmimport --policy-name vmimport --policy-document "file://import/role-policy.json"

## vm 111
#qemu-img convert /mnt/isofiles/briks/images/111/vm-112-disk-0.qcow2 ./112.raw
#aws s3 cp ./111.raw s3://vm-import-images-epitech-tcloud901/112.raw
aws ec2 import-image --description "Master mariadb" --disk-containers "file://import/vm-111-import.json"

## vm 112
#qemu-img convert /mnt/isofiles/briks/images/112/vm-112-disk-0.qcow2 ./112.raw
#aws s3 cp ./111.raw s3://vm-import-images-epitech-tcloud901/112.raw
aws ec2 import-image --description "Slave 1 mariadb" --disk-containers "file://import/vm-112-import.json"

## vm 113
#qemu-img convert /mnt/isofiles/briks/images/113/vm-113-disk-0.qcow2 ./113.raw
#aws s3 cp ./111.raw s3://vm-import-images-epitech-tcloud901/113.raw
aws ec2 import-image --description "Slave 2 mariadb" --disk-containers "file://import/vm-113-import.json"

# monitoring import
#aws ec2 describe-import-image-tasks --import-task-ids import-ami-1234567890abcdef0
