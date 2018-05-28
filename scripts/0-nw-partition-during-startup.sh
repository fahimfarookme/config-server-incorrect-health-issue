#!/bin/bash

source functions.sh

build_project

simulate_network_partition $2
sleep 10s

start_server $1 $2
wait_till_started $1

fix_simulated_network_partition
sleep 10s

printf "\nInvoking /health endpoint...\n"
curl http://localhost:$1/actuator/health

kill -9 $pid_java >> $log_file
printf "\nDONE!\n"

