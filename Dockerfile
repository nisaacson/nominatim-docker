FROM ubuntu:12.04

RUN apt-get update

# Install basic software
RUN apt-get -y install wget


# Note: libgeos++-dev is included here too (the nominatim install page suggests installing it if there is a problem with the 'pear install DB' below - it seems safe to install it anyway)
RUN apt-get -y install build-essential automake
RUN apt-get -y install libxml2-dev
RUN apt-get -y install libgeos-dev
RUN apt-get -y install libpq-dev
RUN apt-get install -y libbz2-dev
RUN apt-get install -y libtool libproj-dev
RUN apt-get install -y libgeos++-dev
RUN apt-get -y install gcc proj-bin libgeos-c1 git osmosis
RUN apt-get -y install php5 php-pear php5-pgsql php5-json

# Some additional packages that may not already be installed
# bc is needed in configPostgresql.sh
RUN apt-get -y install bc

# Install Postgres, PostGIS and dependencies
RUN apt-get -y install postgresql postgis postgresql-contrib postgresql-9.1-postgis postgresql-server-dev-9.1

# Install Apache
RUN apt-get -y install apache2

# Install gdal - which is apparently used for US data (more steps need to be added to this script to support that US data)
RUN apt-get -y install python-gdal

# Add Protobuf support
RUN apt-get -y install libprotobuf-c0-dev protobuf-c-compiler

RUN apt-get install -y sudo

RUN pear install DB
RUN useradd -m -p password1234 nominatim
RUN mkdir -p /app/nominatim
RUN git clone --recursive https://github.com/twain47/Nominatim.git /app/nominatim
RUN cd /app/nominatim && git pull && git submodule update --init
WORKDIR /app/nominatim
RUN ./autogen.sh
RUN ./configure
RUN make

# Configure postgresql
RUN service postgresql start && \
  pg_dropcluster --stop 9.1 main
RUN service postgresql start && \
  pg_createcluster --start -e UTF-8 9.1 main

RUN service postgresql start && \
  sudo -u postgres psql postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='nominatim'" | grep -q 1 || sudo -u postgres createuser -s nominatim && \
  sudo -u postgres psql postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='www-data'" | grep -q 1 || sudo -u postgres createuser -SDR www-data && \
  sudo -u postgres psql postgres -c "DROP DATABASE IF EXISTS nominatim"

RUN wget --output-document=/app/data.pbf http://download.geofabrik.de/north-america-latest.osm.pbf
# RUN wget --output-document=/app/data.pbf http://download.geofabrik.de/north-america/us/delaware-latest.osm.pbf

WORKDIR /app/nominatim
RUN ./utils/setup.php --help


RUN service postgresql start && \
  sudo -u nominatim ./utils/setup.php --osm-file /app/data.pbf --all --threads 2

ADD local.php /app/nominatim/settings/local.php

RUN mkdir -p /var/www/nominatim
RUN ls settings/
RUN cat settings/local.php
RUN ./utils/setup.php --create-website /var/www/nominatim

RUN apt-get install -y curl
ADD 400-nominatim.conf /etc/apache2/sites-available/400-nominatim.conf
ADD httpd.conf /etc/apache2/
RUN service apache2 start && \
  a2ensite 400-nominatim.conf && \
  /etc/init.d/apache2 reload


EXPOSE 8080

ADD configPostgresql.sh /app/nominatim/configPostgresql.sh
WORKDIR /app/nominatim
RUN chmod +x ./configPostgresql.sh
ADD start.sh /app/nominatim/start.sh
RUN chmod +x /app/nominatim/start.sh
CMD /app/nominatim/start.sh
