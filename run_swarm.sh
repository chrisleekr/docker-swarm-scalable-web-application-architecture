#!/bin/bash

# Define list of machine name to launch
#   Currently, three machines will be launched and accessible via docker-machine ssh
#   $ docker-machine ssh manager1
machines=( "manager1"  "worker1" "worker2" )

# Loop defined machines
for machine in "${machines[@]}"
do

	echo "############################################"
	echo "==> 1. Launching machine - $machine"
	echo "############################################"

	echo "==> Remove existing machine if available - $machine"
	docker-machine rm $machine -f

	echo "==> Create new machine - $machine"
	docker-machine create -d virtualbox $machine

    echo "==> Stop newly created machine to add shared folder"
	docker-machine stop $machine

	echo "==> Add current folder as shared folder into docker machine"
	if [ "$(uname)" == "Darwin" ]; then
	    # Do something under Mac OS X platform
	    VBoxManage sharedfolder add $machine --name docker --hostpath $(pwd) --automount
	elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
	    # Do something under GNU/Linux platform
	    VBoxManage sharedfolder add $machine --name docker --hostpath $(pwd) --automount
	elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW64_NT" ]; then
	    # Do something under Windows NT platform
	    "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe" sharedfolder add $machine --name docker --hostpath $(pwd) --automount
	fi

    echo "==> Restart machine - $machine"
	docker-machine start $machine

    echo "==> Create new folder called /docker in root folder"
	docker-machine ssh $machine "sudo mkdir -p /docker"

    echo "==> Mount the shared folder to /docker path with read/write mode"
    if [ "$(uname)" == "Darwin" ]; then
    	docker-machine ssh $machine "sudo mount -t vboxsf -o defaults,dmode=777,fmode=666 docker /docker"
    elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    	docker-machine ssh $machine "sudo mount -t vboxsf -o defaults,dmode=777,fmode=666 docker /docker"
   	elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW64_NT" ]; then
		docker-machine ssh $machine "sudo mount -t vboxsf docker /docker"
	fi

	docker-machine ssh $machine "ls /docker"

done


echo "############################################"
echo "==> 2. Get lead manager host IP Address"
echo "############################################"
#IPADDR=$(docker-machine ssh manager1 ifconfig eth1 | grep 'inet addr:' | cut -d: -f3 | awk '{print $1}')
IPADDR=$(docker-machine ip manager1)
echo "==> Lead Manager IP Address: ${IPADDR}"


echo "############################################"
echo "==> 3. Initialize swarm in lead manager 1"
echo "############################################"
CMD_SWARM_INIT="docker swarm init --advertise-addr ${IPADDR}:2377 --listen-addr ${IPADDR}:2377"
docker-machine ssh manager1 "${CMD_SWARM_INIT}"

echo "==> Get swarm join token for manager from lead manager 1"
SWARM_JOIN_TOKEN=$(docker-machine ssh manager1 docker swarm join-token -q manager)
CMD_SWARM_JOIN="docker swarm join --token ${SWARM_JOIN_TOKEN} ${IPADDR}:2377"
echo "==> Got swarm join command for manager => ${CMD_SWARM_JOIN}"


echo "############################################"
echo "==> 4. Join worker nodes to swarm"
echo "############################################"

echo "==> Get swarm join token for worker from lead manager 1"
SWARM_JOIN_TOKEN=$(docker-machine ssh manager1 docker swarm join-token -q worker)
CMD_SWARM_JOIN="docker swarm join --token ${SWARM_JOIN_TOKEN} ${IPADDR}:2377"
echo "==> Got swarm join command for worker => ${CMD_SWARM_JOIN}"
echo "==> Run swarm join command to worker 1"
docker-machine ssh worker1 ${CMD_SWARM_JOIN}
echo "==> Run swarm join command to worker 2"
docker-machine ssh worker2 ${CMD_SWARM_JOIN}


echo "############################################"
echo "==> 5. Run Docker Swarm Visualizer for monitoring swarm nodes"
echo "		https://github.com/ManoMarks/docker-swarm-visualizer"
echo "############################################"
docker-machine ssh manager1 "docker run -it -d -p 8080:8080 -e HOST=${IPADDR} -v /var/run/docker.sock:/var/run/docker.sock manomarks/visualizer"
#echo "==> Visualizer URL: http://${IPADDR}:8080"


echo "############################################"
echo "==> 6. Run docker registry service to manager images in swarm"
echo "		https://hub.docker.com/_/registry/"
echo "############################################"
docker-machine ssh manager1 "docker service create --name registry --publish 5000:5000 registry:2"
#docker-machine ssh manager1 curl -sS localhost:5000/v2/_catalog
#docker-machine ssh manager1 docker pull alpine
#docker-machine ssh manager1 docker tag alpine localhost:5000/alpine
#docker-machine ssh manager1 docker push localhost:5000/alpine
#docker-machine ssh manager1 curl -sS localhost:5000/v2/_catalog

echo "############################################"
echo "==> 7. Build docker image for Apache & PHP "
echo "      Refer ./docker-app-config/Dockerfile"
echo "############################################"
echo "==> Go to /docker/docker-app-config and build docker image 'docker-app-php'"
docker-machine ssh manager1 "cd /docker/docker-app-config && docker build -t docker-app-php ."
echo "==> Tag built docker image to localhost:5000/docker-app-php"
docker-machine ssh manager1 "docker tag docker-app-php localhost:5000/docker-app-php"
echo "==> Push localhost:5000/docker-app-php to local docker registry"
docker-machine ssh manager1 "docker push localhost:5000/docker-app-php"

echo "############################################"
echo "==> 8. Create docker network 'frontend'"
echo "      All docker services will be laucnhed under the docker network 'frontend' to provide access to each node"
echo "############################################"
docker-machine ssh manager1 "docker network create frontend --driver overlay"

echo "############################################"
echo "==> 9. Run MySQL service in lead manager node"
echo "      Since MySQL replication is not been implemented, launch only one MySQL service in manager only"
echo "############################################"
echo "==> Clean MySQL data folder"
docker-machine ssh manager1 "sudo rm -rf /docker/docker-db-data"
docker-machine ssh manager1 "sudo mkdir -p /docker/docker-db-data"

echo "==> Create service (single instance) for MySQL:5.7 to lead manager node"
docker-machine ssh manager1 "docker service create --name mysql \
	--publish 3306:3306 \
	--network frontend \
	--replicas 1 \
	--mount type=bind,src=/docker/docker-db-data,dst=/var/lib/mysql,readonly=false  \
	--constraint 'node.hostname==manager1' \
	-e MYSQL_ROOT_PASSWORD=root \
	-e MYSQL_DATABASE=docker \
	-e MYSQL_USER=docker \
	-e MYSQL_PASSWORD=docker \
	mysql:5.7 "

echo "############################################"
echo "==> 10. Run Apache & PHP (docker-app-php) service"
echo "############################################"
echo "==> Create service for docker-app-php across swarm node"
docker-machine ssh manager1 "docker service create --name web \
	--publish 80:80 \
	--network frontend \
	--replicas 1 \
	--mount type=bind,src=/docker/docker-app,dst=/var/www/site,readonly=false \
	localhost:5000/docker-app-php:latest"
echo "==> Scale up service to 4"
docker-machine ssh manager1 "docker service scale web=4"

echo "############################################"
echo "==> Visualizer URL: http://${IPADDR}:8080"
echo "==> Web: http://${IPADDR}"
echo "==> MySQL: tcp://${IPADDR}:3306"
echo "############################################"