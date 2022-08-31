#!/bin/bash
for f in $(ls *_test.txt); do 
	RES=$(cat $f | grep 'TEST')
	echo $f $RES
done
