# Nominatim Docker

Run [http://wiki.openstreetmap.org/wiki/Nominatim](http://wiki.openstreetmap.org/wiki/Nominatim) in a docker container. Clones the current master and builds it. This is always the latest version, be cautious as it may be unstable.

Uses Ubuntu 14.04 and PostgreSQL 9.3

# Country
As default it downloads Europe/Monacco (latest) from geofabrik.de during build. This can be changed by setting a build arg.

If a different country should be used, change the wget line in the Dockerfile to pull a different country file.
# Building

To rebuild the image locally execute

```
docker build -t nominatim .
```

# Changing the OSM url to download and use a different country

This example downloads the belize data during compilation:
```
docker build --build-arg OSM=http://download.geofabrik.de/central-america/belize-latest.osm.pbf  -t nominatim .
```

# Running

By default the container exposes port `8080` To run the container execute

```
# remove any existing containers
docker rm -f nominatim_container || echo "nominatim_container not found, skipping removal"
docker run -p 8080:8080 --name nominatim_container --detach nominatim
```

Check the logs of the running container

```
docker logs nominatim_container
```

Stop the container
```
docker stop nominatim_container
```

Connect to the nominatim webserver with curl. If this succeeds, open [http://localhost:8080/](http:/localhost:8080) in a web browser

```
curl "http://localhost:8080"
```
