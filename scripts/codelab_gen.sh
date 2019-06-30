#!/bin/bash
# encoding:utf-8

readonly file="/tmp/$(date +%s).md"
cat md/INDEX.md > $file
cat md/chapters/*.md >> $file
/tmp/claat export -o docs/ $file
rm $file
