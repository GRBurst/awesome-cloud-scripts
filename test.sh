#! /usr/bin/env bash

fail()      ( echo -e "\e[31m[   FAIL] $1 failed\e[0m" )
success()   ( echo -e "\e[32m[SUCCESS] $1 succeeded\e[0m" )
res()  ( (( "$1" == 0 )) && success "$2" || fail "$2" )

[[ "$(./template.sh)" == *"[ERROR] PAR1 parameter required but not provided."* ]]; res $? "missing par1 par"
[[ "$(./template.sh -p1 | tail -n 1)" == *"ENV1 parameter required but not provided"* ]]; res $? "missing par1 val"
[[ "$(./template.sh -p1 "foo")" == *"[ERROR] ENV1 parameter required but not provided."* ]]; res $? "missing env1 par"
[[ "$(./template.sh -p1 "foo" -e1)" == *"[ERROR] Aborting. Not enough values provided for last parameter ENV1"* ]]; res $? "missing env1 val"
[[ "$(ENV1="bar" ./template.sh -p1 "foo" -e1)" == *"[ERROR] Aborting. Not enough values provided for last parameter ENV1"* ]]; res $? "missing env1 val"
[[ "$(./template.sh -p1 "foo" -e1 "bar" | tail -n 1)" == "hello --par1 foo --env1 bar" ]]; res $? "template"
[[ "$(./template.sh -p1 "foo" -e1 "bar" --bool | tail -n 1)" == "hello --bool --par1 foo --env1 bar" ]]; res $? "template with bool"
[[ "$(ENV1="bar" ./template.sh -p1 "foo" | tail -n 1)" == "hello --par1 foo --env1 bar" ]]; res $? "template with env"
[[ "$(ENV1="bar" ./template.sh -p1 "foo" -e1 "meh" | tail -n 1)" == "hello --par1 foo --env1 meh" ]]; res $? "template with env overwrite"
[[ "$(./template.sh -p1 "-b" -e1 "bar" --bool | tail -n 1)" == "hello --bool --par1 -b --env1 bar" ]]; res $? "template with bool parameter and value"
[[ "$(./template.sh -p1 "-e1" -e1 "bar" | tail -n 1)" == "hello --par1 -e1 --env1 bar" ]]; res $? "template with env1 parameter and value"
[[ "$(./template.sh -p1 "foo" -e1 "-p1" | tail -n 1)" == "hello --par1 foo --env1 -p1" ]]; res $? "template with previous par1 parameter and value"
[[ "$(./template.sh -p1 "-e1" -e1 "-p1" | tail -n 1)" == "hello --par1 -e1 --env1 -p1" ]]; res $? "template with env1 and par1 parameter and value"
[[ "$(./template.sh -p1 "-e1" -e1 "-p1" | tail -n 1)" == "hello --par1 -e1 --env1 -p1" ]]; res $? "template with env1 and par1 parameter and value"
[[ "$(./template.sh -p1 "par" -e1 "env" -p2 "foo" | tail -n 1)" == *"[ERROR] Aborting. Not enough values provided for last parameter PAR2"* ]]; res $? "template with one missing par2"
[[ "$(./template.sh -p1 "par" -e1 "env" -p2 "foo" "bar" | tail -n 1)" == "hello --par1 par --par2 foo bar --env1 env" ]]; res $? "template with par2"
[[ "$(./template.sh -p1 "par" -e1 -p2 "foo" "bar" | tail -n 1)" == *"[ERROR] Aborting. Value of -e1 is -p2, which is a parameter, too."* ]]; res $? "template with par2 and missing env1"
