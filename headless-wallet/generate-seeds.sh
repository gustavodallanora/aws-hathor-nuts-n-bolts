#!/bin/bash
if [ $# -eq 0 ]; then
   echo "Missing wallet list parameter!"
   echo "Usage: ./generate-seeds.sh wallet1,wallet2,walletN"
   exit 1
fi

declare -a wallets=($(echo $1 | tr "," "\n"))

declare lastElement=${wallets[-1]}

echo "{" > raw_seeds
## now loop through the above array
for wallet in "${wallets[@]}"
do
   echo "* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * "
   echo "*** Creating seed for $wallet"
   npm run generate_words > $wallet
   if [ $wallet != $lastElement ]; then
      echo "   \"$wallet\": \"`tail -n 1 $wallet`\"," >> raw_seeds
   else
      echo "   \"$wallet\": \"`tail -n 1 $wallet`\"" >> raw_seeds
   fi
done
echo "}" >> raw_seeds

echo ""
echo "Seeds created (words truncated):"
cat raw_seeds | cut -c -80

aws ssm put-parameter --name ${WALLETS_PARAM_NAME} --value $1 --type "String" --overwrite
echo "Keys parameter ${WALLETS_PARAM_NAME} created..."

echo "Keys parameters ${WALLETS_PARAM_NAME} contents:"
aws ssm get-parameter --name ${WALLETS_PARAM_NAME}

aws secretsmanager create-secret --name ${SEEDS_SECRET_NAME} --secret-string "`cat ./raw_seeds`"
echo "Secret ${SEEDS_SECRET_NAME} created..."

echo "Secret ${SEEDS_SECRET_NAME} contents (truncated):"
aws secretsmanager get-secret-value --secret-id ${SEEDS_SECRET_NAME} --query SecretString --output text | cut -c -40
