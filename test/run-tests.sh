#! /usr/bin/env bash

set -Eeuo pipefail

# cd to script location
cd "$(dirname "${BASH_SOURCE[0]}")"

# [[ "$(./template-aws.sh -p nocode-dev | jq -r '.UserId' | cut -d ':' -f2 | cut -d "." -f1 )"=="julius" ]]; res $? "template-aws"

./test-unit.sh \
    --desc "without parameters, missing par1 par error" \
    --expected-result "[ERROR] PAR1 parameter required but not provided."

./test-unit.sh \
    --desc "missing par1 val" \
    --expected-result "[ERROR] ENV1 parameter required but not provided." \
    --parameters "-p1"

./test-unit.sh \
    --desc "missing env1 par" \
    --expected-result "[ERROR] ENV1 parameter required but not provided." \
    --parameters "-p1 foo"

./test-unit.sh \
    --desc "missing env1 val" \
    --expected-result "[ERROR] Aborting. Not enough values provided for last parameter ENV1" \
    --parameters "-p1 foo -e1"

ENV1="bar" ./test-unit.sh \
    --desc "missing env1 value when parameter overwrites environement" \
    --expected-result "[ERROR] Aborting. Not enough values provided for last parameter ENV1" \
    --parameters "-p1 foo -e1"

./test-unit.sh \
    --desc "template with required parameters" \
    --expected-result "hello --default 123 --par1 foo --env1 bar" \
    --parameters "-p1 foo -e1 bar"

./test-unit.sh \
    --desc "template with flag" \
    --expected-result "hello --flag --default 123 --par1 foo --env1 bar" \
    --parameters "-p1 foo -e1 bar --flag"

ENV1="bar" ./test-unit.sh \
    --desc "template with env" \
    --expected-result "hello --default 123 --par1 foo --env1 bar" \
    --parameters "-p1 foo"

ENV1="bar" ./test-unit.sh \
    --desc "template with env overwrite" \
    --expected-result "hello --default 123 --par1 foo --env1 meh" \
    --parameters "-p1 foo -e1 meh"

./test-unit.sh \
    --desc "template with flag parameter and value" \
    --expected-result "hello --flag --default 123 --par1 -b --env1 bar" \
    --parameters "-p1 -b -e1 bar --flag"

./test-unit.sh \
    --desc "template with env1 parameter and value" \
    --expected-result "hello --default 123 --par1 -e1 --env1 bar" \
    --parameters "-p1 -e1 -e1 bar"

./test-unit.sh \
    --desc "template with previous par1 parameter and value" \
    --expected-result "hello --default 123 --par1 foo --env1 -p1" \
    --parameters "-p1 foo -e1 -p1"

./test-unit.sh \
    --desc "template with env1 and par1 parameter and value" \
    --expected-result "hello --default 123 --par1 -e1 --env1 -p1" \
    --parameters "-p1 -e1 -e1 -p1"

./test-unit.sh \
    --desc "template with env1 and par1 parameter and value" \
    --expected-result "hello --default 123 --par1 -e1 --env1 -p1" \
    --parameters "-p1 -e1 -e1 -p1"

./test-unit.sh \
    --desc "template with one missing par2" \
    --expected-result "[ERROR] Aborting. Not enough values provided for last parameter PAR2" \
    --parameters "-p1 par -e1 env -p2 foo"

./test-unit.sh \
    --desc "template with par2" \
    --expected-result "hello --default 123 --par1 par --par2 foo bar --env1 env" \
    --parameters "-p1 par -e1 env -p2 foo bar"

./test-unit.sh \
    --desc "template with par2 and missing env1" \
    --expected-result "[ERROR] Aborting. Value of -e1 is -p2, which is a parameter, too." \
    --parameters "-p1 par -e1 -p2 foo bar"

./test-unit.sh \
    --desc "template with quoted, spaced parameter" \
    --expected-result "hello --default 123 --par1 foo bar --env1 muh" \
    --parameters '-p1 "foo bar" -e1 muh'

./test-unit.sh \
    --desc "template with 2 quoted, spaced parameter" \
    --expected-result "hello --default 123 --par1 foo bar --env1 moo mar" \
    --parameters '-p1 "foo bar" -e1 "moo mar"'

./test-unit.sh \
    --desc "template without short name" \
    --expected-result "hello --default 123 --par1 foo -p3 muh --env1 bar" \
    --parameters "-p1 foo -p3 muh -e1 bar"

./test-unit.sh \
    --desc "template without short name tries to be a flag" \
    --expected-result "[ERROR] Aborting. Value of -p3 is -e1, which is a parameter, too." \
    --parameters "-p1 foo -p3 -e1 bar"

./test-unit.sh \
    --desc "template overwrite default" \
    --expected-result "hello --default 567 --par1 foo -p3 muh --env1 bar" \
    --parameters "-p1 foo -p3 muh -e1 bar --default 567"
