#!/bin/bash
exec &> ./measurement-log.txt

FILE=$1
INTERVAL=$2
CLIENTLIMIT=$3
if [ "$FILE" = "" ] || [ "$INTERVAL" = "" ] || [ "$CLIENTLIMIT" = "" ]
  then
  echo "Please pass in the required arguments."
else
  z=0
  counter=0
  while :
  do
    z=$((z+1))
    echo "Welcome to $z. run"
    if [ "$counter" -lt "$CLIENTLIMIT" ]
    then
      counter=$((counter+1))
      printf "Current date and time: %s\n" "$(date +'%m-%d-%Y %H:%M:%S')"
      echo "Welcome to $counter. request"
      ./cachecash-curl -o "$counter-$FILE" -logLevel=debug cachecash://cachecash.planet-lab.eu:30070/"$FILE" &
    else
      echo "Client Limit Exceeded: $z"
      counter=0
      sleep $INTERVAL
    fi
  done
fi
