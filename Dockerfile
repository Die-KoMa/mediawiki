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
    && a2enconf short-url \
    && sed -i -e 's~DocumentRoot /var/www/html~DocumentRoot /var/www/html\nAlias /wiki /var/www/html~g' "$APACHE_CONFDIR/sites-available/000-default.conf"


RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" \
 && php -r "if (hash_file('sha384', 'composer-setup.php') === 'e0012edf3e80b6978849f5eff0d4b4e4c79ff1609dd1e613307e16318854d24ae64f26d17af3ef0bf7cfb710ca74755a') { echo 'Installer verified'; } else { echo 'Installer corrupt'; unlink('composer-setup.php'); } echo PHP_EOL;" \
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
