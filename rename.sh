#!/bin/bash

# this just renames all the $1 parts of any files that match with the $2 part
# super dangerous, and out of time so made it just copy for now
for i in *$1*; do cp $i $(echo $i | sed "s/${1}/${2}/"); done
chmod +x *.sh
