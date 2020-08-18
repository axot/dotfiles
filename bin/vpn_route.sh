#!/bin/bash

# show network service list
# networksetup -listallnetworkservices
gw=$(networksetup -getinfo Wi-Fi | grep '^Router' | awk '{print $2}')
cmd=$1

# fetch all google cidr
google_cidr=$(for domain in `dig @8.8.8.8 _spf.google.com TXT +short | sed -e 's/"v=spf1//' -e 's/ ~all"//' -e 's/ include:/ /g' | xargs`; do
dig @8.8.8.8 $domain TXT +short | sed -e 's/"v=spf1//' -e 's/ ~all"//' -e 's/ include:/ /g' -e 's/ip.://g' | xargs | grep -v ::
done | tr '\n' ' ')

# also for aws
aws_cidr=$(curl -Ss -o - https://ip-ranges.amazonaws.com/ip-ranges.json | jq -r '.prefixes[].ip_prefix' | tr '\n' ' ')

# add routing
## googles
for cidr in $google_cidr; do
route add -net $cidr $gw || true
done

## aws
for cidr in $aws_cidr; do
route add -net $cidr $gw || true
done

if [ "$cmd" == "rm" ]; then
    for cidr in $google_cidr; do
    route delete -net $cidr $gw || true
    done
fi

# show current route table
netstat -nr -f inet

# test route table
route get 74.125.250.1
