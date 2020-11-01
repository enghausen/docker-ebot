#!/bin/bash

CONTAINER_IP=$(hostname -i)
EXTERNAL_IP="${EXTERNAL_IP:-}"
MYSQL_HOST="${MYSQL_HOST:-mysql}"
MYSQL_PORT="${MYSQL_PORT:-3306}"
MYSQL_USER="${MYSQL_USER:-ebotv3}"
MYSQL_PASS="${MYSQL_PASS:-ebotv3}"
MYSQL_DB="${MYSQL_DB:-ebotv3}"

SSL_ENABLED="${SSL_ENABLED:-true}"
SSL_CERTIFICATE_PATH="${SSL_CERTIFICATE_PATH:-/ssl/cert.pem}"
SSL_KEY_PATH="${SSL_KEY_PATH:-/ssl/key.pem}"

LO3_METHOD="${LO3_METHOD:-restart}"
KO3_METHOD="${KO3_METHOD:-restart}"
DEMO_DOWNLOAD="${DEMO_DOWNLOAD:-true}"
REMIND_RECORD="${REMIND_RECORD:-false}"
DAMAGE_REPORT="${DAMAGE_REPORT:-false}"
DELAY_READY="${DELAY_READY:-false}"
USE_DELAY_END_RECORD="${USE_DELAY_END_RECORD:-true}"

TOORNAMENT_PLUGIN_KEY="${TOORNAMENT_PLUGIN_KEY:-azertylol}"

MAPS="${MAPS:-de_dust2_se,de_nuke_se,de_inferno_se,de_mirage_ce,de_train_se,de_cache,de_season,de_dust2,de_nuke,de_inferno,de_train,de_mirage,de_cbble,de_overpass}"
# Split string by comma into an array
IFS=',' read -ra map_array <<< "$MAPS"

CONFIG_FILE="$EBOT_HOME/config/config.ini"
CONFIG_FILE_SAMPLE="$CONFIG_FILE.smp"
CONFIG_FILE_TMP="$CONFIG_FILE.tmp"

# Remove sample maps
cat $CONFIG_FILE_SAMPLE | grep -v 'MAP\[\] = "' > $CONFIG_FILE_TMP

# Write config.ini file with configured maps
while read line; do
	if [[ "$line" =~ "[MAPS]" ]]; then
		echo $line >> $CONFIG_FILE
		for map in "${map_array[@]}"
		do
			echo "MAP[] = \"$map\"" >> $CONFIG_FILE
		done
	else
		echo $line >> $CONFIG_FILE
	fi
done < $CONFIG_FILE_TMP

rm $CONFIG_FILE_TMP

# for usage with docker-compose
while ! nc -z $MYSQL_HOST $MYSQL_PORT; do sleep 3; done

echo 'date.timezone = "${TIMEZONE}"' >> /usr/local/etc/php/conf.d/php.ini

sed -i "s|BOT_IP =.*|BOT_IP = \"$CONTAINER_IP\"|" $CONFIG_FILE
sed -i "s|EXTERNAL_LOG_IP = .*|EXTERNAL_LOG_IP = \"$EXTERNAL_IP\"|" $CONFIG_FILE
sed -i "s|MYSQL_IP =.*|MYSQL_IP = \"$MYSQL_HOST\"|" $CONFIG_FILE
sed -i "s|MYSQL_PORT =.*|MYSQL_PORT = \"$MYSQL_PORT\"|" $CONFIG_FILE
sed -i "s|MYSQL_USER =.*|MYSQL_USER = \"$MYSQL_USER\"|" $CONFIG_FILE
sed -i "s|MYSQL_PASS =.*|MYSQL_PASS = \"$MYSQL_PASS\"|" $CONFIG_FILE
sed -i "s|MYSQL_BASE =.*|MYSQL_BASE = \"$MYSQL_DB\"|" $CONFIG_FILE
sed -i "s|SSL_ENABLED =.*|SSL_ENABLED = $SSL_ENABLED|" $CONFIG_FILE
sed -i "s|SSL_CERTIFICATE_PATH =.*|SSL_CERTIFICATE_PATH = \"$SSL_CERTIFICATE_PATH\"|" $CONFIG_FILE
sed -i "s|SSL_KEY_PATH =.*|SSL_KEY_PATH = \"$SSL_KEY_PATH\"|" $CONFIG_FILE
sed -i "s|LO3_METHOD =.*|LO3_METHOD = \"$LO3_METHOD\"|" $CONFIG_FILE
sed -i "s|KO3_METHOD =.*|KO3_METHOD = \"$KO3_METHOD\"|" $CONFIG_FILE
sed -i "s|DEMO_DOWNLOAD =.*|DEMO_DOWNLOAD = $DEMO_DOWNLOAD|" $CONFIG_FILE
sed -i "s|REMIND_RECORD =.*|REMIND_RECORD = $REMIND_RECORD|" $CONFIG_FILE
sed -i "s|DAMAGE_REPORT =.*|DAMAGE_REPORT = $DAMAGE_REPORT|" $CONFIG_FILE
sed -i "s|DELAY_READY = .*|DELAY_READY = $DELAY_READY|" $CONFIG_FILE
sed -i "s|USE_DELAY_END_RECORD = .*|USE_DELAY_END_RECORD = $USE_DELAY_END_RECORD|" $CONFIG_FILE

echo -e "\n" >> $EBOT_HOME/config/plugins.ini
echo '[\eBot\Plugins\Official\ToornamentNotifier]' >> $EBOT_HOME/config/plugins.ini
echo "url=https://${EXTERNAL_IP}/matchs/toornament/export/{MATCH_ID}" >> $EBOT_HOME/config/plugins.ini
echo "key=${TOORNAMENT_PLUGIN_KEY}" >> $EBOT_HOME/config/plugins.ini

exec php "$EBOT_HOME/bootstrap.php" 
