#!/bin/bash

qemu-img convert /mnt/isofiles/briks/images/111/vm-111-disk-0.qcow2 ./111.raw
aws s3 cp ./111.raw s3://vm-import/111.raw

aws iam create-role --role-name vmimport --assume-role-policy-document "file://import/trust-policy.json"

aws iam put-role-policy --role-name vmimport --policy-name vmimport --policy-document "file://import/role-policy.json"

aws ec2 import-image --description "My server VM" --disk-containers "file://C:\import\vm-import.json"

# monitoring import
aws ec2 describe-import-image-tasks --import-task-ids import-ami-1234567890abcdef0



ADDRESS=10.10.10.0/24
INSTANCE_ADDRESS=10.10.10.111
KEYNAME=tcloudvpc-keypair
VPC_=TCLOUD901
INFRAGROUP=TCLOUD901
PROJECT=Epitech

get_tag()
{
	echo "--tag-specifications ResourceType=$1,Tags=[{Key=Project,Value=$PROJECT},{Key=Infrastructure,Value=$INFRAGROUP}]"
}

get_describe_value()
{

	FILTER=
	if [ -z "$3" ]; then
		FILTER="--filters Name=tag:Project,Values=$PROJECT"
	fi
	RETURNVAL=$( aws ec2 describe-$1 \
		--query "$2" \
		 $FILTER \
		--output text)
	echo $RETURNVAL
	[ "$RETURNVAL" = "" ]
}

#================================================
# Local Network
#================================================

## Create a VPC
if AWS_VPC_ID=$(get_describe_value "vpcs" "Vpcs[?CidrBlock == '$ADDRESS'].{ID:VpcId}"); then
	AWS_VPC_ID=$(aws ec2 create-vpc \
	--cidr-block $ADDRESS \
	--query 'Vpc.{VpcId:VpcId}' \
	$(get_tag vpc) \
	--output text)
fi
echo AWS_VPC_ID $AWS_VPC_ID

## Create a route table
AWS_CUSTOM_ROUTE_TABLE_ID=$(get_describe_value "route-tables" "RouteTables[?VpcId == '$AWS_VPC_ID'].{ID:RouteTableId}" no_filter)
echo AWS_CUSTOM_ROUTE_TABLE_ID $AWS_CUSTOM_ROUTE_TABLE_ID

## Create an Internet Gateway
if AWS_INTERNET_GATEWAY_ID=$(get_describe_value "internet-gateways" "InternetGateways[*].{ID:InternetGatewayId}"); then
	AWS_INTERNET_GATEWAY_ID=$(aws ec2 create-internet-gateway \
	--query 'InternetGateway.{InternetGatewayId:InternetGatewayId}' \
	$(get_tag internet-gateway) \
	--output text)

	# Attach Internet gateway to your VPC
	AWS_ATTACH_INTERNET_GATEWAY=$(aws ec2 attach-internet-gateway \
	--vpc-id $AWS_VPC_ID \
	--internet-gateway-id $AWS_INTERNET_GATEWAY_ID)
	echo AWS_ATTACH_INTERNET_GATEWAY $AWS_ATTACH_INTERNET_GATEWAY
fi
echo AWS_INTERNET_GATEWAY_ID $AWS_INTERNET_GATEWAY_ID

## Create route to Internet Gateway
AWS_CREATE_ROUTE=$(aws ec2 create-route \
--route-table-id $AWS_CUSTOM_ROUTE_TABLE_ID \
--destination-cidr-block 0.0.0.0/0 \
--gateway-id $AWS_INTERNET_GATEWAY_ID)
echo AWS_CREATE_ROUTE $AWS_CREATE_ROUTE

## getting security group of vpc
AWS_DEFAULT_SECURITY_GROUP=$(get_describe_value "security-groups" "SecurityGroups[?VpcId == '$AWS_VPC_ID'].{ID:GroupId}" no_filter)
echo AWS_DEFAULT_SECURITY_GROUP $AWS_DEFAULT_SECURITY_GROUP

## opening port
if [ "0" = "$(aws ec2 describe-security-groups --query "SecurityGroups[?VpcId == 'vpc-05c467de4e3ea4967']" | grep '\"ToPort\": 22' | wc -l)" ]; then
	aws ec2 authorize-security-group-ingress \
	--group-id $AWS_DEFAULT_SECURITY_GROUP \
	--ip-permissions '[{"IpProtocol": "tcp", "FromPort": 22, "ToPort": 22, "IpRanges": [{"CidrIp": "0.0.0.0/0", "Description": "Allow SSH"}]}]' &&
	echo Authorize 22 port Ok
else
	echo Authorize 22 port already done
fi

## create subnet
if AWS_SUBNET_PUBLIC_ID=$(get_describe_value "subnets" "Subnets[?CidrBlock == '$ADDRESS'].{ID:SubnetId}"); then
	AWS_SUBNET_PUBLIC_ID=$(aws ec2 create-subnet \
	--vpc-id $AWS_VPC_ID \
	--cidr-block $ADDRESS \
	--query 'Subnet.{SubnetId:SubnetId}' \
	$(get_tag subnet) \
	--output text)
fi
echo AWS_SUBNET_PUBLIC_ID $AWS_SUBNET_PUBLIC_ID

#================================================
# Disk
#================================================

## get ami id 
#AWS_AMI_ID=$(get_describe_value "images" "sort_by(Images, &CreationDate)[-1].[ImageId]" no_filter)
AWS_AMI_ID=$(aws ec2 describe-images \
--owners self \
--query 'sort_by(Images, &CreationDate)[-1].[ImageId]' \
--output 'text')
echo AWS_AMI_ID $AWS_AMI_ID

## Create a key-pair
if AWS_KEY_PAIR=$(get_describe_value "key-pairs" "KeyPairs[?KeyName == '$KEYNAME'].{ID:KeyPairId}"); then
	AWS_KEY_PAIR=$(aws ec2 create-key-pair \
	--key-name $KEYNAME \
	--query 'KeyMaterial' \
	$(get_tag key-pair) \
	--output text > $KEYNAME.pem)
fi
echo AWS_KEY_PAIR $AWS_KEY_PAIR

#================================================
# Global
#================================================

## create aws instance
if AWS_EC2_INSTANCE_ID=$(get_describe_value "instances" "Reservations[*].Instances[*].{Instance:InstanceId}"); then
	AWS_EC2_INSTANCE_ID=$(aws ec2 run-instances \
	--image-id $AWS_AMI_ID \
	--instance-type t2.micro \
	--key-name $KEYNAME \
	--monitoring "Enabled=false" \
	--security-group-ids $AWS_DEFAULT_SECURITY_GROUP \
	--subnet-id $AWS_SUBNET_PUBLIC_ID \
	--user-data file://myuserdata.txt \
	$(get_tag instance) \
	--private-ip-address $INSTANCE_ADDRESS \
	--query 'Instances[0].InstanceId' \
	--output text)
fi
echo AWS_EC2_INSTANCE_ID $AWS_EC2_INSTANCE_ID

#================================================
# Public IP
#================================================

## create ip public
if AWS_ELASTIC_IP=$(get_describe_value "addresses" "Addresses[*].{ID:AllocationId}"); then
	AWS_ELASTIC_IP=$(aws ec2 allocate-address \
	$(get_tag elastic-ip) \
	--query "{ID:AllocationId}" \
	--output text)

	## attach ip public
	AWS_ASSOCIATE_ADDRESS=$(ec2 associate-address \
	--instance-id $AWS_EC2_INSTANCE_ID \
	--allocation-id $AWS_ELASTIC_IP)
	echo AWS_ASSOCIATE_ADDRESS $AWS_ASSOCIATE_ADDRESS
fi
echo AWS_ELASTIC_IP $AWS_ELASTIC_IP

