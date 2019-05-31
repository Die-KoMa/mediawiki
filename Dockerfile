FROM mediawiki:1.28

RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
 && php -r "if (hash_file('sha384', 'composer-setup.php') === '48e3236262b34d30969dca3c37281b3b4bbe3221bda826ac6a9a62d6444cdb0dcd0615698a5cbe587c3f0fe57a54d8f5') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" \
 && php composer-setup.php \
 && php -r "unlink('composer-setup.php');"

RUN sed -i 's|^.*jessie-updates.*||' /etc/apt/sources.list

RUN set -ex; \
	\
	apt-get update; \
	apt-get install -y --no-install-recommends \
    libzip-dev \
    unzip \
	; \
	rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-install zip

ADD composer.local.json .
RUN php composer.phar update --no-dev

RUN git clone https://github.com/wikimedia/mediawiki-extensions-Variables.git --branch REL1_28 extensions/Variables
