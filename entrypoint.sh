#!/bin/bash

# Domain for SSL and eBot settings
DOMAIN="${DOMAIN:-ebot.doamin.com}"

# MYSQL settings
MYSQL_HOST="${MYSQL_HOST:-mysql}"
MYSQL_PORT="${MYSQL_PORT:-3306}"
MYSQL_USER="${MYSQL_USER:-ebotv3}"
MYSQL_PASSWORD="${MYSQL_PASSWORD:-ebotv3}"
MYSQL_DATABASE="${MYSQL_DATABASE:-ebotv3}"

# eBot settings
CONTAINER_IP=$(hostname -i)
EBOT_PORT="${EBOT_PORT:-12360}"
DELAY_BUSY_SERVER="${DELAY_BUSY_SERVER:-120}"
NB_MAX_MATCHS="${NB_MAX_MATCHS:-0}"
PAUSE_METHOD="${PAUSE_METHOD:-nextRound}"
NODE_STARTUP_METHOD="${NODE_STARTUP_METHOD:-none}"
LO3_METHOD="${LO3_METHOD:-restart}"
KO3_METHOD="${KO3_METHOD:-restart}"
DEMO_DOWNLOAD="${DEMO_DOWNLOAD:-true}"
REMIND_RECORD="${REMIND_RECORD:-true}"
DAMAGE_REPORT="${DAMAGE_REPORT:-false}"
USE_DELAY_END_RECORD="${USE_DELAY_END_RECORD:-true}"
COMMAND_STOP_DISABLED="${COMMAND_STOP_DISABLED:-false}"
RECORD_METHOD="${RECORD_METHOD:-matchstart}"
DELAY_READY="${DELAY_READY:-true}"

# SSL settings
SSL_ENABLED="${SSL_ENABLED:-true}"
SSL_CERTIFICATE_PATH="${SSL_CERTIFICATE_PATH:-$EBOT_HOME/ssl/$DOMAIN/fullchain.cer}"
SSL_KEY_PATH="${SSL_KEY_PATH:-$EBOT_HOME/ssl/$DOMAIN/$DOMAIN.key}"

# Toonament settings
TOORNAMENT_PLUGIN_KEY="${TOORNAMENT_PLUGIN_KEY:-}"

# PHP settings
TIMEZONE="${TIMEZONE:-Europe/Copenhagen}"

# Custom maps in config.ini
MAPS="${MAPS:-de_dust2_se,de_nuke_se,de_inferno_se,de_mirage_ce,de_train_se,de_cache,de_season,de_dust2,de_nuke,de_inferno,de_train,de_mirage,de_cbble,de_overpass}"

# Split string by comma into an array
IFS=',' read -ra map_array <<< "$MAPS"

# Config paths and files
CONFIG_FILE="$EBOT_HOME/config/config.ini"
CONFIG_FILE_SAMPLE="$CONFIG_FILE.smp"
CONFIG_FILE_TMP="$CONFIG_FILE.tmp"

# Remove sample maps
cat $CONFIG_FILE_SAMPLE | grep -v 'MAP\[\] = "' > $CONFIG_FILE_TMP
rm -f $CONFIG_FILE

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

# For enable SSL and secureUpload on the websocket with forever
FOREVER_SSL="${FOREVER_SSL:-TRUE}"
FOREVER_SECUREUPLOAD="${FOREVER_SECUREUPLOAD:-TRUE}"

# For usage with docker-compose
while ! nc -z $MYSQL_HOST $MYSQL_PORT; do sleep 3; done

# Manage eBot config (config.ini)
sed -i "s|MYSQL_IP =.*|MYSQL_IP = \"$MYSQL_HOST\"|" $CONFIG_FILE
sed -i "s|MYSQL_PORT =.*|MYSQL_PORT = \"$MYSQL_PORT\"|" $CONFIG_FILE
sed -i "s|MYSQL_USER =.*|MYSQL_USER = \"$MYSQL_USER\"|" $CONFIG_FILE
sed -i "s|MYSQL_PASS =.*|MYSQL_PASS = \"$MYSQL_PASSWORD\"|" $CONFIG_FILE
sed -i "s|MYSQL_BASE =.*|MYSQL_BASE = \"$MYSQL_DATABASE\"|" $CONFIG_FILE
sed -i "s|BOT_IP =.*|BOT_IP = \"$CONTAINER_IP\"|" $CONFIG_FILE
sed -i "s|BOT_PORT =.*|BOT_PORT = $EBOT_PORT|" $CONFIG_FILE
sed -i "s|SSL_ENABLED =.*|SSL_ENABLED = $SSL_ENABLED|" $CONFIG_FILE
sed -i "s|SSL_CERTIFICATE_PATH =.*|SSL_CERTIFICATE_PATH = \"$SSL_CERTIFICATE_PATH\"|" $CONFIG_FILE
sed -i "s|SSL_KEY_PATH =.*|SSL_KEY_PATH = \"$SSL_KEY_PATH\"|" $CONFIG_FILE
sed -i "s|EXTERNAL_LOG_IP = .*|EXTERNAL_LOG_IP = \"$DOMAIN\"|" $CONFIG_FILE
sed -i "s|DELAY_BUSY_SERVER = .*|DELAY_BUSY_SERVER = $DELAY_BUSY_SERVER|" $CONFIG_FILE
sed -i "s|NB_MAX_MATCHS = .*|NB_MAX_MATCHS = $NB_MAX_MATCHS|" $CONFIG_FILE
sed -i "s|PAUSE_METHOD = .*|PAUSE_METHOD = \"$PAUSE_METHOD\"|" $CONFIG_FILE
sed -i "s|NODE_STARTUP_METHOD =.*|NODE_STARTUP_METHOD = \"$NODE_STARTUP_METHOD\"|" $CONFIG_FILE
sed -i "s|LO3_METHOD =.*|LO3_METHOD = \"$LO3_METHOD\"|" $CONFIG_FILE
sed -i "s|KO3_METHOD =.*|KO3_METHOD = \"$KO3_METHOD\"|" $CONFIG_FILE
sed -i "s|DEMO_DOWNLOAD =.*|DEMO_DOWNLOAD = $DEMO_DOWNLOAD|" $CONFIG_FILE
sed -i "s|REMIND_RECORD =.*|REMIND_RECORD = $REMIND_RECORD|" $CONFIG_FILE
sed -i "s|DAMAGE_REPORT =.*|DAMAGE_REPORT = $DAMAGE_REPORT|" $CONFIG_FILE
sed -i "s|USE_DELAY_END_RECORD = .*|USE_DELAY_END_RECORD = $USE_DELAY_END_RECORD|" $CONFIG_FILE
sed -i "s|COMMAND_STOP_DISABLED = .*|COMMAND_STOP_DISABLED = $COMMAND_STOP_DISABLED|" $CONFIG_FILE
sed -i "s|RECORD_METHOD =.*|RECORD_METHOD = \"$RECORD_METHOD\"|" $CONFIG_FILE
sed -i "s|DELAY_READY = .*|DELAY_READY = $DELAY_READY|" $CONFIG_FILE

# Manage plugins config (plugins.ini)
sed -i "s|;\[\\\eBot\\\Plugins\\\Official\\\T.*|\[\\\eBot\\\Plugins\\\Official\\\ToornamentNotifier\]|" $EBOT_HOME/config/plugins.ini
sed -i "s|;url=http://y.*|url=https://$DOMAIN/matchs/toornament/export/{MATCH_ID}|" $EBOT_HOME/config/plugins.ini
sed -i "s|;key=.*|key=$TOORNAMENT_PLUGIN_KEY|" $EBOT_HOME/config/plugins.ini

# PHP config
sed -i "s|date.timezone =.*|date.timezone = \"$TIMEZONE\"|" /usr/local/etc/php/conf.d/php.ini

# Start the websocket with forever and execute the boostrap (secureUpload enabled by default. /upload is therefor only avalible from private IPs)
forever start $EBOT_HOME/websocket_server.js $CONTAINER_IP $EBOT_PORT $FOREVER_SSL $SSL_CERTIFICATE_PATH $SSL_KEY_PATH $FOREVER_SECUREUPLOAD
exec php "$EBOT_HOME/bootstrap.php" 
