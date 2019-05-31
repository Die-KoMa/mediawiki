FROM mediawiki:1.28
ENV MW_VERSION REL1_28


# Enable Short URLs
RUN a2enmod rewrite \
  && { \
      echo '<Directory /var/www/html>'; \
      echo '  RewriteEngine On'; \
      echo '  RewriteCond %{REQUEST_FILENAME} !-f'; \
      echo '  RewriteCond %{REQUEST_FILENAME} !-d'; \
      echo '  RewriteRule ^ %{DOCUMENT_ROOT}/index.php [L]'; \
      echo '</Directory>'; \
    } > "$APACHE_CONFDIR/conf-available/short-url.conf" \
  && a2enconf short-url


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

RUN cd extensions && set -ex; \
  git clone --branch ${MW_VERSION} https://github.com/wikimedia/mediawiki-extensions-Variables.git Variables \
  ; \
  git clone --branch ${MW_VERSION} https://github.com/wikimedia/mediawiki-extensions-EditSubpages.git EditSubpages \
  ; \
  git clone --branch ${MW_VERSION} https://github.com/wikimedia/mediawiki-extensions-UserMerge.git UserMerge \
  ;
