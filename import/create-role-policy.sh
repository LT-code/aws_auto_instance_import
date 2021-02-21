. $(echo $1)

print_buckets()
{
  for i in "${REGIONS_IP_NUM[@]}";
  do
    echo "            \"arn:aws:s3:::$BUCKET_NAME$i\"," >> $FILENAME
    printf "            \"arn:aws:s3:::$BUCKET_NAME$i/*\"" >> $FILENAME
    if [ "$i" != "${REGIONS_IP_NUM[-1]}" ]; then
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
