#!/bin/bash
# encoding:utf-8

apt-get update && apt-get install -y curl jq

./download_claat.sh

./codelab_gen.sh
