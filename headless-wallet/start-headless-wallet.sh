#!/bin/bash

# Prepare seeds
echo "Preparing Seeds..."
cd /home/ec2-user/
source /home/ec2-user/.bash_profile

# Fetch secret
aws secretsmanager get-secret-value --secret-id ${SEEDS_SECRET_NAME} --query SecretString --output text > seeds
if [ $? -eq 0 ]
then
  echo "Found ${SEEDS_SECRTE_NAME} secret, continuing..."
else
  echo ""
  echo "Aborting wallet start..."
  echo "You must configure ${SEEDS_SECRET_NAME} secret using this instance, delete the stack and create it again."
  exit 1;
fi

mapfile -t arr < <(jq -r 'keys[]' seeds)
printf "%s\n" ${arr[@]} > seed_keys
sed -i '1s/^/seeds: /' seeds
echo , >> seeds

echo ""
echo "Got this seeds (words truncated):"
cat seeds | cut -c -40

# Configure wallet
echo "Configuring wallet..."
cd hathor-wallet-headless
cp config.js.template src/config.js
sed -i -E "s/(http_bind_address: ').*(',)/\10.0.0.0\2/" src/config.js && cat src/config.js | grep http_bind_address:
sed -i -E "s/(network: ').*(',)/\1${NETWORK_NAME}\2/" src/config.js && cat src/config.js | grep network:
sed -i -E "s,(server: ').*('\,),\1${NETWORK_SERVER}\2," src/config.js && cat src/config.js | grep server:
perl -i -p0e 's/seeds: {.*?}\n/`cat ..\/seeds`/se' src/config.js && cat src/config.js | grep seeds: -A 10 | cut -c -40

echo "Starting node..."
cd /home/ec2-user/hathor-wallet-headless
nohup npm start > /home/ec2-user/logs/headless-wallet.log 2>&1 &

echo "Waiting 15 seconds for node to go up..."
sleep 15

# Init wallets from seed and check status
while read line; do echo "$line" && curl -X POST --data "wallet-id=$line" --data "seedKey=$line" http://localhost:8000/start && echo " "; done < ../seed_keys
while read line; do echo "$line" && curl -X GET -H "X-Wallet-Id: $line" http://localhost:8000/wallet/status/ && echo " "; done < ../seed_keys

echo "Done."
