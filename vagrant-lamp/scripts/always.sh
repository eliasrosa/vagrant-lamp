#!/usr/bin/env bash

# Install Mailcatcher
# ---------------------------------
#mailcatcher --http-ip=192.168.33.22
mailcatcher --http-ip=0.0.0.0


# Limpa os arquivos de Log
# ---------------------------------
echo "Truncate error.log and access.log"
truncate -s 0 /var/www/html/error.log
truncate -s 0 /var/www/html/access.log


# Lista todos ips
# ---------------------------------
ifconfig | perl -nle 's/dr:(\S+)/print "IP: $1"/e'

