echo "Starting node..."
cd /home/ec2-user/hathor-wallet-headless
nohup npm start > ~/headless-wallet.log 2>&1 &

echo "Waiting 15 seconds for node to go up..."
sleep 15

# Init wallets from seed and check status
while read line; do echo "$line" && curl -X POST --data "wallet-id=$line" --data "seedKey=$line" http://localhost:8000/start && echo " "; done < ../seed_keys
while read line; do echo "$line" && curl -X GET -H "X-Wallet-Id: $line" http://localhost:8000/wallet/status/ && echo " "; done < ../seed_keys
