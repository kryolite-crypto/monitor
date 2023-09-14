#!/usr/bin/env bash

set -eEuo pipefail

_fetch() {
  curl -Lsf --max-time 10 -o "$2" "$1"
}

delay=$1
samples=$2
discord_webhook=$3
while true
do
  for (( i=1; i<=$samples; i++ ))
  do
    _fetch https://testnet-1.kryolite.io/chainstate "/tmp/testnet-1-$i" &
    _fetch https://testnet-2.kryolite.io/chainstate "/tmp/testnet-2-$i" &
    wait

    printf "\n" >> "/tmp/testnet-1-$i"
    printf "\n" >> "/tmp/testnet-2-$i"

    sleep $delay
  done

  samesame=0
  butdifferent=0
  for (( i=1; i<=$samples; i++ ))
  do
    if diff "/tmp/testnet-1-$i" "/tmp/testnet-2-$i"
    then
      samesame=$((samesame+1))
    else
      butdifferent=$((butdifferent+1))
    fi
  done

  echo "samesame: $samesame butdifferent: $butdifferent"

  if [[ $samesame == 0 ]]
  then
    TEMP_FILE="/tmp/last_alarm_time.txt"

    if [[ -f $TEMP_FILE ]]
    then
      current_hour=$(date +"%H")
      last_alarm_hour=$(cat $TEMP_FILE)

      if [[ $current_hour -eq $last_alarm_hour ]]; then
        echo "Alarm already sent in this hour."
        continue
      fi
    fi

    echo "Sending alarm..."

    date +"%H" > $TEMP_FILE
    curl -X POST -H "Content-Type: application/json" -d '{"content": "testnet-1 and testnet-2 differ"}' "$discord_webhook"
  fi

done
