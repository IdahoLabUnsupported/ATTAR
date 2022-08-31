# Attack Test Harness (ATTAR) Readme
v1.0.0

## Description
The Attack Test Harness (ATTAR) is a tool designed to run processes and validate that the process has ran. It can be used remotely and distributes the test scripts via ssh, it also runs and can return the results of the script via ssh. To avoid typing passwords ssh keys are used, and can be installed automaticaly using the hosts.sh script which will be explained later. In a nutshell what the testharness does is transfer scripts laid out in a csv file to a host specified in a hosts.csv file and runs them piping all the results to the original location, afterwhich it runs a second script to test the results and ensure they are as expected. 

The main.sh script is the heart of the whole operation all of the other scripts are just helper scripts or files consumed by main.sh. It is important to understand the user need not understand how main.sh works, users only need to know how to create test scripts and add them to the list in tests.csv, however if the user studies and understands main.sh they can understand how the whole test harness works. 

In a nutshell main.sh will look for and run scripts based off the lines in tests.csv, it knows which script to run because of the naming convention used. The main.sh script will run the script and pipe the output to a txt file, then it will run the version of the script with the original script name followed by '_test' and pipe the output to another text file. The text file outputs have the same name as the script, but have the extension .txt. The idea behind this operation is the first script is ran to do whatever is to be done, then the second script '_test' is ran to validate that the first script was successful, normally by checking the output of the txt file from the first script.

Everything is based on the strong naming convention, all that needs to be done for main.sh to work is the test scripts need to be named exactly as they are defined in tests.csv, see below for more details. 

## Example
As a simple example the eternal blue attack will be demonstrated. This example will explain every step of the process as the attack runs and is validated. This assumes that the eternal blue attack is the only one listed in the tests.csv file. 

1. User runs main.sh from a location that can reach a kali vm 
2. main.sh reads tests.csv to see which test it should run
3. main.sh uses hosts.sh to get username and ip of target where test will run
4. main.sh uses scp to move attackvm1_eternalblue1.sh to root@172.16.100.250:/tmp
5. main.sh runs the script it just transfered in (4) piping the output locally to attackvm1_eternalblue.txt
6. main.sh checks to see if attackvm1_eternalblue.txt exists, if so it runs attackvm1_eternalblue1_test.sh
7. attackvm1_eternalblue1_test.sh checks the output of attackvm1_eternalblue.txt for the 'WIN' text result is piped to attackvm1_eternalblue1_test.txt
8. main.sh moves onto the next test in tests.csv if it exists

## Quick Start, Test Creation
This is a quick guide to explain how to create a new test. In this example we assume everything else is already setup and the test harness is being ran on a compute node while there is a kali vm accessable at the same address as in the example above. 

1. Add test to tests.csv in this format, in a new line at the bottom

>`attackvm1;eternalblue2;another eb;`

2. Create a script to be ran on the kali vm, and another to validate the first script's output

>`touch attackvm1_eternalblue2.sh; touch attackvm1_eternalblue2_test.sh: chmod +x *.sh`

3. Add code to attackvm1_eternalblue2.sh as desired, this code will run on the kalivm in /tmp
4. Add code to attackvm1_eternalblue2_test.sh to check the output from attackvm1_eternalblue2.txt and return a 'TEST PASS' or 'TEST FAIL' exactly like in attackvm1_eternalblue1_test.sh. In fact attackvm1_eternalblue1_test.sh can be copied and simply changed on line8 to look at 'eternalblue2'

## Naming convention
In the tests.csv the format is as follows

`{host};{test_name};{note};`

host: the name of a host defined in hosts.csv
test_name: unique name of test
note: can be anything assuming it is alphanumeric, avoid any other chars

These same variables from tests.csv are used to know which scripts to copy and run, as well as what to name the output from the scripts. 

The script that will be pushed to the host and ran should be named like this:

`{host}.{test_name}.sh`

And the script that will be ran locally that consumes the output of the previous script should be named like this:

`{host}.{test_name}_test.sh`

In the hosts.csv the format is as follows

`{host};{username};{ip}`

host: is the unique hostname used to look up this host, it is used to match off of what's in tests.csv
username: the username to use (we assume ssh keys are installed, else user will have to type password)
ip: the ip address to use to push the scripts and run them








