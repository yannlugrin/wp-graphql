#!/usr/bin/env bash

set -eu

copy_wordpress_files() {
  cp -a /usr/src/wordpress/* /var/www/html/ 2> /dev/null || true
}

wait_for_database() {
  set +e
  while [[ true ]]; do
    if curl --fail --show-error --silent "${WORDPRESS_DB_HOST}:3306" > /dev/null 2>&1; then break; fi
      echo "Waiting for database to be ready...."
      sleep 2
  done
  set -e
}

configure_wordpress_and_plugin() {
  wp --allow-root config create --dbname="${WORDPRESS_DB_NAME}" --dbuser="${WORDPRESS_DB_USER}" --dbpass="${WORDPRESS_DB_PASSWORD}" --dbhost="${WORDPRESS_DB_HOST}" --skip-check --force=true
  wp --allow-root core install --url='http://wpgraphql.test' --title='WPGraphQL Tests' --admin_user='admin' --admin_password='password' --admin_email='admin@wpgraphql.test' --skip-email
  wp --allow-root rewrite structure '/%year%/%monthnum%/%postname%/'

  # activate the plugin
  wp --allow-root plugin activate wp-graphql

  # Flush the permalinks
  wp --allow-root rewrite flush --hard

  # Export sql data for Codeception's use
  # TODO: Is this really needed?
  # wp --allow-root db export "$(pwd)/tests/_data/dump.sql"

  chown 'www-data:www-data' wp-config.php .htaccess
}

run_wordpress() {
  docker-entrypoint.sh 'apache2-foreground'
}

main() {
  copy_wordpress_files
  wait_for_database
  configure_wordpress_and_plugin
  run_wordpress
}

main
