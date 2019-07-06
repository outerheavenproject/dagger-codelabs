#!/bin/bash
# encoding:utf-8

readonly base_dir="/tmp/dagger_codelabs"
readonly file="$base_dir/$(date +%s).md"

mkdir $base_dir

cp md/chapters/*.png "$base_dir/."

cat md/INDEX.md > $file
cat md/chapters/*.md >> $file
/tmp/claat export -o docs/ $file

rm -r $base_dir
