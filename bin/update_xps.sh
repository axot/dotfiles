#!/bin/sh
PATH=/usr/local/bin:$PATH
LOG="/tmp/update_xps.log"

export DOCKER_TLS_VERIFY="0"
export DOCKER_HOST=tcp://xps:2376
export DOCKER_CERT_PATH=/Users/axot/.docker/machine/machines/xps
export DOCKER_MACHINE_NAME="xps"
export DOCKER_API_VERSION=1.23

exec 1<&-
exec 2<&-
exec 1<>"$LOG"

echo Pull new images...
cd $HOME/Dropbox/Config/Server/xps
docker-compose -p docker build --pull 2>&1
docker-compose -p docker pull 2>&1
docker build -t data_backup data_backup 2>&1
echo %

echo Restart all containers...
docker-compose -p docker up -d 2>&1
sleep 60
echo %

echo Remove stopped containers, and old images...
docker images | grep '<none>' | awk '{print $3}' | xargs -I{} docker rmi {}
echo %

echo List of docker containers
docker ps -a --format "table {{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Names}}" 2>&1
echo %

echo List all images
docker images 2>&1
echo %

cat "$LOG" | grep -v '^$' | mail -s 'RE: XPS Update Report' axot@axot.org
rm "$LOG"
