#!/bin/bash
# Use curl command to upload file at S3 bucket.
#upload to S3 bucket 
sourceFilePath="/mnt/isofiles/briks/images/100/vm-100-disk-0.qcow2";

#file path at S3
filePathAtS3="111.qcow2";

#Your S3 bucket name
bucket="proxmox-mariadb-images";

#S3 HTTP Resource URL for your file
resource="/${bucket}/${filePathAtS3}";

#set content type
#contentType="application/zip";

#get date as RFC 7231 format
dateValue=`date -jnu +%a,\ %d\ %h\ %Y\ %T\ %Z`;

#String to generate signature
stringToSign="PUT\n\n${contentType}\n${dateValue}\n${resource}";

#your S3 key. This is specific to S3. This is not your AWS username.
s3Key="";

#your S3 secret. This is specific to S3. This is not your AWS password.
s3Secret="";

#Generate signature, Amazon re-calculates the signature and compares if it matches the one that was contained in your request. That way the secret access key never needs to be transmitted over the network.
signature=`echo -en ${stringToSign} | openssl sha1 -hmac ${s3Secret} -binary | base64`;

##Use curl to make PUT request. 
#curl -L -X PUT -T "${sourceFilePath}" \
# -H "Host: s3.amazonaws.com" \
# -H "Date: ${dateValue}" \
# -H "Content-Type: ${contentType}" \
# https://proxmox-mariadb-images.s3.amazonaws.com/${filePathAtS3}
curl -L -X PUT -T "${sourceFilePath}" \
 -H "Authorization: AWS ${s3Key}:${signature}" \
 https://proxmox-mariadb-images.s3.amazonaws.com/${filePathAtS3}
 #-H "Date: ${dateValue}" \
 #-H "Content-Type: ${contentType}" \
 #https://s3.amazonaws.com/${bucket}/${filePathAtS3}
kkkkk
