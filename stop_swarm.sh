#!/bin/bash


machines=( "manager1"  "worker1" "worker2" )
for machine in "${machines[@]}"
do
	docker-machine rm $machine -f
done