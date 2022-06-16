#!/bin/bash
if [ $# -eq 0 ]; then
   echo "Missing wallet list parameter!"
   echo "Usage: ./create-seeds wallet1,wallet2,wallet"
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