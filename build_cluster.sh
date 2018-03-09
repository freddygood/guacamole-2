#!/bin/bash

function log() {
	local M=$1
#	echo $(date +"%H:%M:%S %d/%m/%Y") $M
	echo "$M"
}

function err() {
	local M=$1 RC=${2:-1}
	log "$M. Exiting.."
	exit $RC
}


NODES=2
BACKEND='nginx'
FRONTEND='haproxy'
NETWORK='exness'
PORT='8088'
STATS_SLEEP=5
DOCKER_REGISTERY='freddygood'

while [ "$1" ]; do
	case "$1" in
		'--force')    DO_FORCE=true ;;
		'--all')      DO_ALL=true ;;
		'--images')   DO_IMAGES=true ;;
		'--network')  DO_NETWORK=true ;;
		'--backend')  DO_BACKEND=true ;;
		'--frontend') DO_FRONTEND=true ;;
		'--stats')    DO_STATS=true ;;
		'--clean')    DO_CLEAN=true ;;
	esac
	shift
done

# create images
if [[ $DO_ALL || $DO_IMAGES ]]; then
	pushd nginx
	docker build -t ${DOCKER_REGISTERY}/${BACKEND}:latest . || err "Error creating nginx image"
	popd
	pushd haproxy
	docker build -t ${DOCKER_REGISTERY}/${FRONTEND}:latest . || err "Error creating haproxy image"
	popd

	docker images
fi

# create network
if [[ $DO_ALL || $DO_NETWORK ]]; then
	[ $DO_FORCE ] && docker network rm $NETWORK
	docker network create $NETWORK
	docker network inspect $NETWORK
fi

# create backend containers
if [[ $DO_ALL || $DO_BACKEND ]]; then
	mkdir -p runtime/nginx-confd runtime/nginx-static
	cp nginx/backend.conf runtime/nginx-confd/
	rsync -a --delete nginx/static/ runtime/nginx-static/
	for N in $(seq 1 $NODES); do
		NODE="${BACKEND}${N}"
		IMAGE="${DOCKER_REGISTERY}/${BACKEND}:latest"
		[ $DO_FORCE ] && docker rm -f $NODE >/dev/null
		docker run -d \
			--network $NETWORK \
			--name $NODE \
			--volume $(pwd)/runtime/nginx-confd:/etc/nginx/conf.d \
			--volume $(pwd)/runtime/nginx-logs-$N:/var/log/nginx \
			--volume $(pwd)/runtime/nginx-static:/www/static \
			$IMAGE >/dev/null
		NODE_ID=$(docker inspect --format='{{.Id}}' $NODE)
		NODE_IP=$(docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $NODE)
		log "Created container '$NODE'"
		log " - ID '$NODE_ID'"
		log " - IP address '$NODE_IP'"
	done
fi

# create frontend containers
if [[ $DO_ALL || $DO_FRONTEND ]]; then
	mkdir -p runtime/haproxy-confd
	cp haproxy/haproxy.cfg runtime/haproxy-confd/
	for N in $(seq 1 $NODES); do
		NODE="${FRONTEND}${N}"
		IMAGE="${DOCKER_REGISTERY}/${FRONTEND}:latest"
		let NODE_PORT=PORT+N-1
		[ $DO_FORCE ] && docker rm -f $NODE >/dev/null
		docker run -d \
			--network $NETWORK \
			--name $NODE \
			--volume $(pwd)/runtime/haproxy-confd:/etc/haproxy \
			--volume $(pwd)/runtime/haproxy-logs-$N:/var/log \
			--publish ${NODE_PORT}:80 \
			$IMAGE >/dev/null
		NODE_ID=$(docker inspect --format='{{.Id}}' $NODE)
		NODE_IP=$(docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $NODE)
		log "Created container '$NODE'"
		log " - ID '$NODE_ID'"
		log " - IP address '$NODE_IP'"
	done
fi

# show statistics
if [[ $DO_ALL || $DO_STATS ]]; then
	[ $DO_ALL ] && sleep $STATS_SLEEP

	echo
	log "Cluster information:"
	for N in $(seq 1 $NODES); do
		NODE="${FRONTEND}${N}"
		docker inspect $NODE >/dev/null 2>&1 || continue
		let NODE_PORT=PORT+N-1
		log " - Container '$NODE' entry point:"
		log "   - http://127.0.0.1:${NODE_PORT}/index.html"
		log " - Backend aliveness:"
		curl -s "http://127.0.0.1:${NODE_PORT}/haproxy?stats;csv" | grep ^${BACKEND} | grep -v ^${BACKEND}.BACKEND | grep 'UP' | awk -F, '{printf "%s: %s\n", $2, $18}' | while read M; do
			log "   - $M"
		done
	done

	echo
	log "Frontend working containers:"
	for N in $(seq 1 $NODES); do
		NODE="${FRONTEND}${N}"
		docker inspect $NODE >/dev/null 2>&1 || continue
		let NODE_PORT=PORT+N-1
		NODE_ID=$(docker inspect --format='{{.Id}}' $NODE)
		NODE_IP=$(docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $NODE)
		log " - Container '$NODE'"
		log "   - ID '$NODE_ID'"
		log "   - IP address '$NODE_IP'"
		log "   - Exposed port '$NODE_PORT'"
	done

	echo
	log "Backend working containers:"
	for N in $(seq 1 $NODES); do
		NODE="${BACKEND}${N}"
		docker inspect $NODE >/dev/null 2>&1 || continue
		NODE_ID=$(docker inspect --format='{{.Id}}' $NODE)
		NODE_IP=$(docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $NODE)
		log " - Container '$NODE'"
		log "   - ID '$NODE_ID'"
		log "   - IP address '$NODE_IP'"
	done
fi

# clean
if [[ $DO_CLEAN ]]; then
	log "Cleaning frontend"
	for N in $(seq 1 $NODES); do
		NODE="${FRONTEND}${N}"
		log " - $NODE"
		docker rm -f $NODE >/dev/null
	done

	log "Cleaning backend"
	for N in $(seq 1 $NODES); do
		NODE="${BACKEND}${N}"
		log " - $NODE"
		docker rm -f $NODE >/dev/null
	done

	log "Cleaning network"
	log " - $NETWORK"
	docker network rm $NETWORK >/dev/null

	log "Cleaning images"
	docker rmi ${DOCKER_REGISTERY}/${BACKEND}:latest
	docker rmi ${DOCKER_REGISTERY}/${FRONTEND}:latest
fi
