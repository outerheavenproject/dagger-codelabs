#!/bin/bash
# encoding:utf-8

readonly url=$(curl https://api.github.com/repos/googlecodelabs/tools/releases/latest | \
    jq -r '.assets[] | select(.name == "claat-linux-amd64") | .url')
curl -LJ -o /tmp/claat -H 'Accept: application/octet-stream' $url
chmod u+x /tmp/claat
