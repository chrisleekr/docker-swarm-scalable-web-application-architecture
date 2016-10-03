FROM ubuntu:latest
MAINTAINER Chris Lee <chrislee.kr>

# Upgrade system and install Apache, php7, php7-mysql
RUN apt-get update && apt-get -y upgrade && DEBIAN_FRONTEND=noninteractive apt-get -y install \
    apache2 php7.0 php7.0-mysql libapache2-mod-php7.0

# Enable Apache mods
RUN a2enmod php7.0
RUN a2enmod rewrite

# Configure Apache environment variables
ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2
ENV APACHE_LOCK_DIR /var/lock/apache2
ENV APACHE_PID_FILE /var/run/apache2.pid

# Expose Apache port 80
EXPOSE 80

# Copy 000-default.conf to apache site config folder
ADD 000-default.conf /etc/apache2/sites-enabled/000-default.conf

# Start apache in the foreground
CMD /usr/sbin/apache2ctl -D FOREGROUND