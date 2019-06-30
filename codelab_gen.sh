#!/bin/bash
# encoding:utf-8

readonly file="/tmp/$(date +%s).md"
cat $(find md -name "*.md"  | sort) > $file
claat export -o docs/ $file
rm $file
