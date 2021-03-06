#!/bin/bash

source set_env.sh

function build_project() {
   printf "\nBuilding the project, please wait..."

   cd ../config-server
   ./mvnw clean package >> $log_file
}

function start_server() {
   printf "\nStarting the config-server on port $1, please wait..."

   debug="-Xdebug -Xrunjdwp:server=y,transport=dt_socket,address=$(( $1 + 10 )),suspend=n"
   JAVA_OPTIONS="-Dconfig.server.port=$1 -Dconfig.repo.username=${env_map[config_repo_username_$2]} -Dconfig.repo.password=${env_map[config_repo_password_$2]} -Dconfig.repo.uri=${env_map[config_repo_uri_$2]} -Dconfig.server.clone.dir=./target/local-repo -Dspring.profiles.active=$2 $debug"
   printf "\nJAVA_OPTIONS=$JAVA_OPTIONS" 1>>$log_file

   $JAVA_HOME/bin/java $JAVA_OPTIONS -jar target/config-server-0.0.1-SNAPSHOT.jar >> $log_file &
   pid_java=$! 
}

function wait_till_started {
   until [ "`curl -s -o /dev/null -w "%{http_code}" --show-error --connect-timeout 1 --max-time 10 http://localhost:$1/actuator/info 2>>$log_file | grep '200'`" != "" ];
   do
      sleep 10s
   done

   printf "\nConfig-server is started on port $1"
}

function invoke_health_endpoint {
   curl --silent http://localhost:$1/actuator/health &
   sleep 0.3s
   invoke_health_endpoint $1
}


function simulate_network_partition {
   printf "\nSimulating a network partition for dns ${env_map[config_repo_dns_$1]}..."
   dig +short ${env_map[config_repo_dns_$1]} > target/ips.txt

   while read ip; do
      sudo iptables -A INPUT -s $ip -j DROP      
   done < target/ips.txt
}

function fix_simulated_network_partition {
   printf "\nReverting the simulated network partition..."

   while read ip; do
      sudo iptables -D INPUT -s $ip -j DROP      
   done < target/ips.txt
}

if [ "$#" -ne 2 ]
then
   printf "Please provide port and profile (git or svn) as arguments.\n"
   exit -1
fi

if [ $EUID != 0 ]; then
    sudo "$0" "$@"
    exit $?
fi

