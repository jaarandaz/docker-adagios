FROM debian:wheezy

ENV DEBIAN_FRONTEND noninteractive

ENV NAGIOSADMIN_USER nagiosadmin
ENV NAGIOSADMIN_PASS nagios

ENV APACHE_RUN_USER nagios
ENV APACHE_RUN_GROUP nagios
ENV APACHE_LOCK_DIR /var/run
ENV APACHE_LOG_DIR /var/log/apache2

RUN echo "deb http://opensource.is/repo/debian wheezy main" > /etc/apt/sources.list.d/opensource.is.list
RUN apt-get update -y

# Install pre-requisits
RUN apt-get install nagios3 git libapache2-mod-wsgi check-mk-livestatus pynag runit sudo --force-yes -y

# Install adagios
RUN apt-get install adagios --force-yes -y

# If you plan on using the built-in status view in adagios you need these:
RUN pynag config --append "broker_module=/usr/lib/check_mk/livestatus.o /var/lib/nagios3/rw/livestatus"

# New objects created with adagios go here, make sure nagios is reading
# that directory
RUN mkdir -p /etc/nagios3/adagios
RUN pynag config --append cfg_dir=/etc/nagios3/adagios

# Create git repo which adagios uses for version control
WORKDIR /etc/nagios3/
RUN git init
RUN git add .
RUN git commit -a -m "Initial commit"

# Make sure nagios group will always have write access to the configuration files:
RUN chown -R nagios /etc/nagios3 /etc/adagios

# Install pnp4nagios and get graphs working
RUN apt-get install pnp4nagios -y
RUN pynag config --set "process_performance_data=1"
RUN pynag config --append "broker_module=/usr/lib/pnp4nagios/npcdmod.o config_file=/etc/pnp4nagios/npcd.cfg"
RUN usermod -G www-data nagios
RUN sed -i 's/RUN.*/RUN="yes"/' /etc/default/npcd

# Clean stuff
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/* \
           /tmp/* \
           /var/tmp/*

RUN rm -rf /etc/sv/getty-5
RUN mkdir -p /etc/sv/nagios && mkdir -p /etc/sv/apache
ADD nagios.init /etc/sv/nagios/run
ADD apache.init /etc/sv/apache/run
ADD npcd.init /etc/sv/npcd/run

ADD start.sh /usr/local/bin/start_adagios

EXPOSE 80

CMD ["/usr/local/bin/start_adagios"]
