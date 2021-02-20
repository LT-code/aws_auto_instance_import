INSTANCES=( $1 )
BUCKET_NAME=$2
FILENAME=import/role-policy.json

print_buckets()
{
  for i in "${INSTANCES[@]}";
  do
    echo "            \"arn:aws:s3:::$BUCKET_NAME$i\"," >> $FILENAME
    printf "            \"arn:aws:s3:::$BUCKET_NAME$i/*\"" >> $FILENAME
    if [ "$i" != "${INSTANCES[-1]}" ]; then
      echo "," >> $FILENAME
    fi
  done
}

echo "{
   \"Version\":\"2012-10-17\",
   \"Statement\":[
      {
         \"Effect\": \"Allow\",
         \"Action\": [
            \"s3:GetBucketLocation\",
            \"s3:GetObject\",
            \"s3:ListBucket\" 
         ],
         \"Resource\": [" > $FILENAME


print_buckets

echo "         ]
      },
      {
         \"Effect\": \"Allow\",
         \"Action\": [
            \"s3:GetBucketLocation\",
            \"s3:GetObject\",
            \"s3:ListBucket\",
            \"s3:PutObject\",
            \"s3:GetBucketAcl\"
         ],
         \"Resource\": [" >> $FILENAME

print_buckets

echo "         ]
      },
      {
         \"Effect\": \"Allow\",
         \"Action\": [
            \"ec2:ModifySnapshotAttribute\",
            \"ec2:CopySnapshot\",
            \"ec2:RegisterImage\",
            \"ec2:Describe*\"
         ],
         \"Resource\": \"*\"
      },
      {
	\"Effect\": \"Allow\",
  	\"Action\": [
  	  \"license-manager:GetLicenseConfiguration\",
  	  \"license-manager:UpdateLicenseSpecificationsForResource\",
  	  \"license-manager:ListLicenseSpecificationsForResource\"
  	],
  	\"Resource\": \"*\"
      }
   ]
}" >> $FILENAME
