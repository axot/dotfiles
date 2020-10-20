#!/bin/bash

function run_maybe_dry() {
  if [[ -z $DRY_RUN ]];
  then
    eval $@
  else
    echo $@
  fi
}

function usage() {
  echo "Usage: $0 [-s|--setup] [-c|--cleaning] [--network-service] [--dry-run]"
  exit
}

# Parsing command line arguments
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
  -h|--help)
  usage
  shift
  shift
  ;;
  -c|--cleaning)
  CLEANING=1
  shift
  ;;
  -s|--setup)
  SETUP=1
  shift
  ;;
  --dry-run)
  DRY_RUN=1
  shift
  ;;
  --network-service)
  NETWORK_SERVICE=$2
  shift
  shift
  ;;
  *)
  echo "Unknown argument $1"
  echo
  usage
  ;;
esac
done

# fetch all google cidr
google_cidr=$(for domain in `dig @8.8.8.8 _spf.google.com TXT +short | sed -e 's/"v=spf1//' -e 's/ ~all"//' -e 's/ include:/ /g' | xargs`; do
dig @8.8.8.8 $domain TXT +short | sed -e 's/"v=spf1//' -e 's/ ~all"//' -e 's/ include:/ /g' -e 's/ip.://g' | xargs | grep -v ::
done | tr '\n' ' ')

if [[ -z $NETWORK_SERVICE ]]; then
  echo Select the Network when VPN was not used:
  OIFS=$IFS
  IFS=$'\n'
  select NETWORK_SERVICE in $(networksetup -listallnetworkservices | tail -n +2); do
     break
  done
  IFS=$OIFS
fi

gw=$(networksetup -getinfo "$NETWORK_SERVICE" | grep '^Router' | awk '{print $2}')

echo NETWORK SERVICE: "$NETWORK_SERVICE", gateway IP: $gw

[[ $gw =~ ^[0-9] ]] || { echo "gateway IP is not correct, exiting..."; exit; }

if [[ -n $SETUP ]]; then
  # add routing
  ## googles
  for cidr in $google_cidr; do
    run_maybe_dry route add -net $cidr $gw
  done
fi

if [[ -n $CLEANING ]]; then
  for cidr in $google_cidr; do
     run_maybe_dry route delete -net $cidr $gw
  done
fi

echo
echo current route table
run_maybe_dry netstat -nr -f inet

# test route table
## esmeralda
echo
echo test esmeralda
run_maybe_dry route get 35.200.8.8

## google
echo
echo test google
run_maybe_dry route get 8.8.8.8
