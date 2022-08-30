#! /usr/bin/env bash

# [[ "$(./template-aws.sh -p nocode-dev | jq -r '.UserId' | cut -d ':' -f2 | cut -d "." -f1 )"=="julius" ]]; res $? "template-aws"

./test-unit.sh \
    --name "missing par1 par" \
    --expected-result "[ERROR] PAR1 parameter required but not provided."

./test-unit.sh \
    --name "missing par1 val" \
    --expected-result "[ERROR] ENV1 parameter required but not provided." \
    --parameters "-p1"

./test-unit.sh \
    --name "missing env1 par" \
    --expected-result "[ERROR] ENV1 parameter required but not provided." \
    --parameters "-p1 foo"

./test-unit.sh \
    --name "missing env1 val" \
    --expected-result "[ERROR] Aborting. Not enough values provided for last parameter ENV1" \
    --parameters "-p1 foo -e1"

ENV1="bar" ./test-unit.sh \
    --name "missing env1 val" \
    --expected-result "[ERROR] Aborting. Not enough values provided for last parameter ENV1" \
    --parameters "-p1 foo -e1"

./test-unit.sh \
    --name "template" \
    --expected-result "hello --par1 foo --env1 bar" \
    --parameters "-p1 foo -e1 bar"

./test-unit.sh \
    --name "template with bool" \
    --expected-result "hello --bool --par1 foo --env1 bar" \
    --parameters "-p1 foo -e1 bar --bool"

ENV1="bar" ./test-unit.sh \
    --name "template with env" \
    --expected-result "hello --par1 foo --env1 bar" \
    --parameters "-p1 foo"

ENV1="bar" ./test-unit.sh \
    --name "template with env overwrite" \
    --expected-result "hello --par1 foo --env1 meh" \
    --parameters "-p1 foo -e1 meh"

./test-unit.sh \
    --name "template with bool parameter and value" \
    --expected-result "hello --bool --par1 -b --env1 bar" \
    --parameters "-p1 -b -e1 bar --bool"

./test-unit.sh \
    --name "template with env1 parameter and value" \
    --expected-result "hello --par1 -e1 --env1 bar" \
    --parameters "-p1 -e1 -e1 bar"

./test-unit.sh \
    --name "template with previous par1 parameter and value" \
    --expected-result "hello --par1 foo --env1 -p1" \
    --parameters "-p1 foo -e1 -p1"

./test-unit.sh \
    --name "template with env1 and par1 parameter and value" \
    --expected-result "hello --par1 -e1 --env1 -p1" \
    --parameters "-p1 -e1 -e1 -p1"

./test-unit.sh \
    --name "template with env1 and par1 parameter and value" \
    --expected-result "hello --par1 -e1 --env1 -p1" \
    --parameters "-p1 -e1 -e1 -p1"

./test-unit.sh \
    --name "template with one missing par2" \
    --expected-result "[ERROR] Aborting. Not enough values provided for last parameter PAR2" \
    --parameters "-p1 par -e1 env -p2 foo"

./test-unit.sh \
--name "    template with par2" \
    --expected-result "hello --par1 par --par2 foo bar --env1 env" \
    --parameters "-p1 par -e1 env -p2 foo bar"

./test-unit.sh \
--name "    template with par2 and missing env1" \
    --expected-result "[ERROR] Aborting. Value of -e1 is -p2, which is a parameter, too." \
    --parameters "-p1 par -e1 -p2 foo bar"
