#!/bin/bash

source functions.sh

build_project
start_server $1 $2
wait_till_started $1

printf "\nInvoking /health endpoint before N/W partition...\n"
curl http://localhost:$1/actuator/health

simulate_network_partition $2
sleep 10s

printf "\nInvoking /health endpoint after N/W partition...\n"
curl http://localhost:$1/actuator/health

kill -9 $pid_java >> $log_file
fix_simulated_network_partition
printf "\nDONE!\n"

