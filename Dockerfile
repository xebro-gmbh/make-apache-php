FROM php:8.4-apache-bookworm AS base

ENV TZ=Europe/Berlin
ENV HISTFILE=/var/www/html/.bash_history

RUN DEBIAN_FRONTEND=noninteractive \
    apt-get update -q \
    && DEBIAN_FRONTEND=noninteractive apt-get install -qq -y \
      curl \
      git \
      gosu \
      rsync \
      tzdata \
      unzip \
      zip

ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/
RUN chmod uga+x /usr/local/bin/install-php-extensions && sync

RUN install-php-extensions \
      bcmath \
      bz2 \
      exif \
      gd \
      intl \
      opcache \
      pcntl \
      pdo_pgsql \
      pgsql \
      redis \
      soap \
      xml \
      xsl \
      zip

RUN cp $PHP_INI_DIR/php.ini-production $PHP_INI_DIR/php.ini


RUN cp $PHP_INI_DIR/php.ini-production $PHP_INI_DIR/php.ini
ADD ./config/php.ini "$PHP_INI_DIR/conf.d/xxx-prod-php.ini"
ADD ./config/000-default.conf /etc/apache2/sites-enabled/000-default.conf
ADD ./config/apache2.conf /etc/apache2/apache2.conf

# Set timezone to Berlin
RUN ln -fs /usr/share/zoneinfo/$TZ /etc/localtime \
    && dpkg-reconfigure -f noninteractive tzdata

WORKDIR /var/www/html


FROM base AS dev

ENV COMPOSER_HOME /composer_data
ENV COMPOSER_CACHE_DIR /composer

RUN install-php-extensions xdebug

RUN mkdir -p ${COMPOSER_HOME} ; \
    mkdir -p ${COMPOSER_CACHE_DIR}

ADD ./config/install_composer.sh /var/scripts/
RUN chmod +x /var/scripts/install_composer.sh ; /var/scripts/install_composer.sh
RUN chmod -R 0777 ${COMPOSER_HOME}

RUN cp $PHP_INI_DIR/php.ini-development $PHP_INI_DIR/php.ini
ADD ./config/php-dev.ini "$PHP_INI_DIR/conf.d/xxx-dev-php.ini"

FROM dev AS ci
