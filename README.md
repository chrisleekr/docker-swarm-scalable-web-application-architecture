# Deploying scalable web application with Docker Swarm Mode and Docker Machine 

This is proof-of-concept project to set up Docker Swarm in development environment with single command.

This project involves:
* Docker Machine
* Docker Swarm 
* Local Docker Registry 
* Docker Network 
* Docker Service 

![Alt text](/screenshots/0_docker_swarm_architecture_diagram.png?raw=true "Docker Swarm Architecture Diagram")

Note: This project is created for just practice. Not suitable for production use.


# Prerequisites
* Docker 1.12.1+: <https://www.docker.com/>
* VirtualBox: <https://www.virtualbox.org/>

# Usage
```
    $ git clone https://github.com/chrisleekr/docker-swarm-scalable-web-application-architecture.git
    $ cd docker-swarm-scalable-web-application-architecture
    $ ./run_swarm.sh
```

After shell script is completed, you can connect instances to:
* Visualizer UI: http://${MANAGER1_IP}:8500
* Web Access: http://${MANAGER1_IP}
* DB Access: tcp://${MANAGER1_IP}:3306

[![asciicast](https://asciinema.org/a/e6vingukodlxxfk97mdqd4tpv.png?autoplay=1)](https://asciinema.org/a/e6vingukodlxxfk97mdqd4tpv)

Note: Any node IP will be accessible to instances, not only manager1 node IP.

To stop all machines, run *stop_swarm.sh*
```
    $ ./stop_swarm.sh
```

# Features
* Launch multiple Docker Machines and configure Docker Swarm automatically
* Demonstrate Docker Swarm which is introduced in Docker 1.12.1+
* Deploy local Docker Registry, which can use pull images across swarm nodes (https://hub.docker.com/_/registry/)
* Build docker image via Dockerfile in Docker Machine and push to local Docker Registry
* Create service with Docker Hub image MySQL (https://hub.docker.com/_/mysql/)
* Create service with custom build docker image (./docker-app-config/Dockerfile)
* Emulate scaling up for launched service


# Screenshots
![Alt text](/screenshots/1_docker_swarm_visualizer.png?raw=true "Docker Swarm Visualizer")
![Alt text](/screenshots/2_docker_swarm_apache_web.png?raw=true "Docker Swarm Web Access")
![Alt text](/screenshots/3_docker_swarm_apache_web.png?raw=true "Docker Swarm Web Access")
![Alt text](/screenshots/4_docker_swarm_mysql_access.png?raw=true "Docker Swarm DB Access")

# How it works
*Note* This section is a bit descriptive for reference purpose.

1. Launching docker machine *manager1*
    1. Remove existing docker machine *manager1*
    2. Create new docker machine *manager1*
    3. Stop newly created machine to add shared folder
    4. Add current folder as shared folder to docker machine
    5. Restart docker machine *manager1*
    6. Create new folder /docker into docker machine *manager1*
    7. Mount shared folder to /docker
2. Launching docker machine *worker1* 
    1.  Repeat aforementioned step #1-i to #1-vii
3. Launching docker machine *worker2*
    1.  Repeat aforementioned step #1-i to #1-vii
4. Get lead manager *manager1* host IP address
5. Initialize swarm in lead manager *manager1*
    1. Get swarm join token for manager node
    2. Construct swarm join command for manager node
    3. Run join command to join manager nodes
6. Join worker nodes to swarm
    1. Get swarm join token for worker node
    2. Construct swarm join command for worker node
    3. Run join command to join worker node *worker1*
    4. Run join command to join worker node *worker2*
7. Launch docker container *manomarks/visualizer*
8. Launch docker registry service *registry:2*
9. Build docker image for service *web* (Apache+PHP)
    1. Go to */docker/docker-app-config* and build docker image *docker-app-php*
    2. Tag built docker image to *localhost:5000/docker-app-php*
    3. Push *localhost:5000/docker-app-php* to local docker registry
10. Create docker network *frontend*
11. Run MySQL service in docker machine *manager1*
    1. Clean MySQL data folder
    2. Create *mysql* service (single instance) for MySQL:5.7 to *manager1* node
12. Run Apache & PHP *docker-app-php* service
    1. Create *web* service for docker image *docker-app-php* across swarm nodes
    2. Scale up *web* service to 4 instances
    