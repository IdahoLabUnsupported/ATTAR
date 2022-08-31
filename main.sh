#!/bin/bash
# dont use sh or you will get bad subs

# this is ran by the test dameon on the testvm
# it waits for the feature output file and then runs the test
# it takes care of markers and outputting to results file

# function to test return values
check_ret () {
	if [ $? -ne 0 ]; then echo "error $?"; exit 1; fi
}
# function to check if file exists
file_exists () {
	if [ ! -f "$1" ]; then echo "not found $1"; exit 1; fi
}

if [ -z "$1" ]; then
	echo "must provide scope as argument"
	exit 1
fi

echo "Warning all old txt files are deleted! Do not store txt in this dir"
rm *.txt

basedir="."
cd $basedir
# ensure we got tests.csv
file_exists "${basedir}/tests.csv"

scope=$1

echo "limiting tests to scope $scope"

OLDIFS=$IFS
IFS=";"
while read -r host scope feature note
	do
		# print information

		# if they prefix with comment # skip that test
		# SILENT skip of all this
		if [[ "$host" =~ ^#.* ]]; then
			#echo "skip, commented out"
			continue
		fi

		if [[ "$scope" != "$1" ]]; then
			#echo "skip, not in scope"
			continue
		fi

		echo $(date)
		echo $host $scope $feature $note

		# run attack on target 
		IP=$(./hosts.sh ${host})
		UN=$(./hosts.sh ${host} un)
		PW=$(./hosts.sh ${host} pw)
		FN=${host}_${scope}_${feature}.txt
		
		# lets put a timestamp on the test
		echo $(date) >> $FN

		# if they are local, dont ssh
		if [ "$host" == "local" ]; then
			# copy and run locally
			cp ${basedir}/${host}_${scope}_${feature}.sh /tmp/
			# if we need to use an env file
			if [ -f ${basedir}/${host}.env ]; then
				cp ${basedir}/${host}.env /tmp/
			fi

			IDX=$(date '+%Y-%m-%d')
			FEAT="${scope}-${feature}"
			URL="http://172.16.60.55:9200/bennu-$IDX/_doc"

			STAGE="start"
			TS=$(date --iso-8601=seconds)
			DATA="{\"@timestamp\": \"$TS\", \"attack\": true, \"name\": \"$FEAT\", \"stage\": \"$STAGE\"}"

			#curl -k -X POST "$URL" -H 'Content-Type: application/json' -d "$DATA" &> /dev/null
			
			chmod +x /tmp/${host}_${scope}_${feature}.sh; /tmp/${host}_${scope}_${feature}.sh >> $FN 2>&1

			STAGE="finish"
			TS=$(date --iso-8601=seconds)
			DATA="{\"@timestamp\": \"$TS\", \"attack\": true, \"name\": \"$FEAT\", \"stage\": \"$STAGE\"}"

			#curl -k -X POST "$URL" -H 'Content-Type: application/json' -d "$DATA" &> /dev/null

		else	# scp to another host and run
			# if we need to use an env file
			if [ -f ${basedir}/${host}.env ]; then
				sshpass -p ${PW} scp -o StrictHostKeyChecking=no ${basedir}/${host}.env $UN@${IP}:/tmp/
			fi
			# not sure if these will work with key anymore the '-i thkey'
			sshpass -p ${PW} scp -o StrictHostKeyChecking=no ${basedir}/${host}_${scope}_${feature}.sh $UN@${IP}:/tmp/
			sshpass -p ${PW} ssh -n -o StrictHostKeyChecking=no $UN@${IP} "chmod +x /tmp/${host}_${scope}_${feature}.sh; /tmp/${host}_${scope}_${feature}.sh" >> $FN 2>&1
		fi

		# if the result exists
		if [ -f ${basedir}/${host}_${scope}_${feature}.txt ]; then # run test on results
			# ensure it does not have marker
			# single thread for now
			#grep ${basedir}/${host}_${feature}_MARKER ${basedir}/${host}_${feature}_test.txt
			#if [ $? -ne 0 ]; then # we test 
			if [ 1 -eq 1 ]; then # we test 
				# remove marker for now
				#echo "${basedir}/${host}_${feature}_MARKER $(date)" >> ${basedir}/${host}_${feature}_test.txt
				echo $(date) | tee ${basedir}/${host}_${scope}_${feature}_test.txt
				${basedir}/${host}_${scope}_${feature}_test.sh ${basedir}/${host}_${scope}_${feature}.txt ${basedir}/${host}_${scope}_${feature} | tee ${basedir}/${host}_${scope}_${feature}_test.txt 2>&1
				# below is if we wanted to have a html report
				#echo "<a href=\"./${basedir}/${host}_${scope}_${feature}_test.txt\">${basedir}/${host} Results</a>" >> index.html
			else
				echo "${basedir}/${host}_${scope}_${feature}.txt MARKER exists, test done"
				
			fi
		else
			echo "ERROR: ${basedir}/${host}_${scope}_${feature}.txt result does not exist, moving on"
		fi
done < "${basedir}/tests.csv"
echo "------------------------"
echo "Done in $SECONDS seconds"
IFS=$OLDIFS

