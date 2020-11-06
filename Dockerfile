FROM php:5.6.40-zts-jessie

ENV EBOT_HOME="/ebot" \
    TIMEZONE="Europe/Copenhagen"

RUN apt-get update -y && apt-get install -y netcat git nodejs npm libcurl4-gnutls-dev && apt-get clean && \
    mkdir ${EBOT_HOME} && \
    ln -s /usr/bin/nodejs /usr/bin/node && \
    npm install socket.io@0.9.19 archiver@0.21.0 formidable@1.2.2 && \
    npm install -g forever@1.0.1 && \
    pecl install pthreads-2.0.10 && \
    docker-php-ext-enable pthreads && \
    docker-php-ext-install mysql sockets curl && \
    echo 'date.timezone = "${TIMEZONE}"' >> /usr/local/etc/php/conf.d/php.ini && \
    php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
    php composer-setup.php --install-dir=/usr/bin && \
    php -r "unlink('composer-setup.php');" && \
    git clone https://github.com/enghausen/eBot-CSGO.git ${EBOT_HOME} && \
    cd ${EBOT_HOME} && git checkout "master" && \
    /usr/local/bin/php /usr/bin/composer.phar install && \
    mkdir ${EBOT_HOME}/ssl

WORKDIR ${EBOT_HOME}

COPY entrypoint.sh /sbin/entrypoint.sh

RUN chmod +x /sbin/entrypoint.sh

EXPOSE 12360 12360/udp 12361/udp

ENTRYPOINT ["/sbin/entrypoint.sh"]
