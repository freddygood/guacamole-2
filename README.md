# guacamole-2 readme file

### Creating images

`./build_cluster.sh --images`

Creates images of haproxy and nginx containers

### Creating network

`./build_cluster.sh --network [--force]`

Creates network for container deployment (re-creates if --force used)

### Creating backend containers

`./build_cluster.sh --backend [--force]`

Creates 2 docker containers with nginx (re-creates if --force used)

### Creating frontend containers

`./build_cluster.sh --frontend [--force]`

Creates 2 haproxy containers with nginx (re-creates if --force used)

### Displaying cluster statistics

`./build_cluster.sh --stats`

Shows cluster entrypoints and backend aliveness, and backend and frontend information as well

### Running in batch

`./build_cluster.sh --all [--force]`

Alias of `./build_cluster.sh --images --network --backend --frontend --stats [--force]`

### Cleaning cluster

`./build_cluster.sh --clean`

Deletes all containers, network and images

### Please enjoy!