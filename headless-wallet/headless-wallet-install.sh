# Install NodeJS
echo Installing NodeJS...
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.34.0/install.sh | bash
. ~/.nvm/nvm.sh
nvm install 16
node -e "console.log('Running Node.js ' + process.version)" > /home/ec2-user/headless-wallet.log

# Prepare seeds
echo Preparing Seeds...
aws secretsmanager get-secret-value --secret-id ${SEEDS_SECRET_NAME} --query SecretString --output text > seeds
mapfile -t arr < <(jq -r 'keys[]' seeds)
printf "%s\n" ${arr[@]} > seed_keys
sed -i '1s/^/seeds: /' seeds
echo , >> seeds


# Clone last version of the wallet source code configure and start
echo Installing and configuring wallet...
cd /home/ec2-user
git clone https://github.com/HathorNetwork/hathor-wallet-headless.git
cd hathor-wallet-headless
cp config.js.template src/config.js
sed -i -E "s/(http_bind_address: ').*(',)/\10.0.0.0\2/" src/config.js && cat src/config.js | grep http_bind_address:
sed -i -E "s/(network: ').*(',)/\1${NETWORK_NAME}\2/" src/config.js && cat src/config.js | grep network:
sed -i -E "s,(server: ').*('\,),\1${NETWORK_SERVER}\2," src/config.js && cat src/config.js | grep server:
perl -i -p0e 's/seeds: {.*?}\n/`cat ..\/seeds`/se' src/config.js && cat src/config.js | grep seeds: -A 10

npm install
