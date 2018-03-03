# guacamole-2 readme file

### Creating images

`./build_cluster.sh --images`

Creates images of haproxy and nginx containers

You should replace variable $DOCKER_REGISTERY with a name of your docker hub account if you're planning re-create images

### Creating docker machines

`./build_cluster.sh --machines`

Creates local docker machines with driver virtualbox. Assumed that VirtualBox is installed.

### Creating docker swarm stack

`./build_cluster.sh --stack`

Creates docker swarm stack.

### Displaying cluster statistics

Shows cluster statistics such as entrypoints and backend aliveness

`./build_cluster.sh --stats`
