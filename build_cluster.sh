#!/bin/bash

function log() {
	local M=$1
	echo $(date +"%H:%M:%S %d/%m/%Y") $M
}

function err() {
	local M=$1 RC=${2:-1}
	log "$M. Exiting.."
	exit $RC
}


NODES='node1 node2'
SWARM_MASTER='node1'
STACK_NAME='exness'
BACKEND='nginx'
FRONTEND='haproxy'
STATS_SLEEP=60
DOCKER_REGISTERY='freddygood'
#export VIRTUALBOX_BOOT2DOCKER_URL='https://github.com/boot2docker/boot2docker/releases/download/v17.12.0-ce/boot2docker.iso'

while [ "$1" ]; do
	case "$1" in 
		'--all')      ALL=true ;;
		'--machines') MACHINES=true ;;
		'--images')   IMAGES=true ;;
		'--stack')    STACK=true ;;
		'--stats')    STATS=true ;;
	esac
	shift
done

# create images
if [[ $ALL || $IMAGES ]]; then
	eval $(docker-machine env --unset)
	pushd haproxy
	docker build -t ${DOCKER_REGISTERY}/haproxy:latest . || err "Error creating haproxy image"
	popd
	pushd nginx
	docker build -t ${DOCKER_REGISTERY}/nginx:latest . || err "Error creating nginx image"
	popd

	docker image prune -f

	docker login
	docker push ${DOCKER_REGISTERY}/haproxy:latest
	docker push ${DOCKER_REGISTERY}/nginx:latest

	docker images
fi

# create machines
if [[ $ALL || $MACHINES ]]; then
	eval $(docker-machine env --unset)
	for NODE in $NODES; do
		docker-machine inspect $NODE >/dev/null 2>&1 && docker-machine rm -f $NODE
	done

	for NODE in $NODES; do
		docker-machine create --driver virtualbox $NODE
	done

	eval $(docker-machine env $SWARM_MASTER)
	SWARM_MASTER_IP=$(docker-machine ip $SWARM_MASTER)
	docker swarm init --advertise-addr $SWARM_MASTER_IP

	TOKEN=$(docker swarm join-token -q worker)
	SWARM_ADD_COMMAND="docker swarm join --token ${TOKEN} ${SWARM_MASTER_IP}:2377"

	for NODE in $NODES; do
		[ $NODE != $SWARM_MASTER ] && docker-machine ssh $NODE $SWARM_ADD_COMMAND
	done

	log "IP of Docker Swarm master ${SWARM_MASTER} is $SWARM_MASTER_IP"
	docker node ls
	eval $(docker-machine env --unset)
	echo "Run eval \$(docker-machine env $SWARM_MASTER) to setup env"
fi

# create registry container
if [[ $ALL || $STACK ]]; then
	eval $(docker-machine env $SWARM_MASTER)
	docker stack deploy --compose-file docker-compose.yml $STACK_NAME
	docker stack services $STACK_NAME
	eval $(docker-machine env --unset)

	echo "Cluster entry points:"
	for NODE in $NODES; do
		IP=$(docker-machine ip $NODE)
		echo "http://${IP}/index.html"
	done
fi

# show statistics
if [[ $ALL || $STATS ]]; then
	[ $ALL ] && sleep $STATS_SLEEP
	SWARM_MASTER_IP=$(docker-machine ip $SWARM_MASTER)
	echo "Backend statistics:"
	curl -s "http://${SWARM_MASTER_IP}/haproxy?stats;csv" | grep ^${BACKEND} | grep 'UP' | awk -F, '{print $2, $18}'
fi
