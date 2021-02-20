REGIONS=( $1 )
MASTER_REGION=${REGIONS[$2]}
MASTER_PASSWORD=$3
SLAVE_PASSWORD=$4

TEST_VALUE="test-replication-presentation-$(date +"%d%m%Y%H%M%S")"

get_public_ip() {
  aws ec2 describe-addresses \
      --filters Name=tag:aws:cloudformation:stack-name,Values=mariadb \
      --query "Addresses[*].PublicIp" \
      --output text \
      --region $1
}


mysql -u replication_user \
        -h $(get_public_ip $MASTER_REGION) \
        --password="$MASTER_PASSWORD" \
        -e "insert into test value ('$TEST_VALUE');" \
        "test"


for i in "${REGIONS[@]}";
do
  if [ "$i" != "$MASTER_REGION" ]; then
    PUBLIC_IP=$(get_public_ip $i)
    RES=$(mysql -u presentation \
      -h $PUBLIC_IP \
      --password="$SLAVE_PASSWORD" \
      -e "select * from test;" "test")
    
    if [ "$(echo $RES | grep "$TEST_VALUE" | wc -l)" = "1" ]; then
      echo "OK | $i mariadb instance with IP:$PUBLIC_IP passed the test"
    else
      echo "ERR | $i mariadb instance with IP:$PUBLIC_IP is not set correctly"
      echo RESON : $RES
      exit -1
    fi
  fi
done
