#!/bin/bash

sudo apt-get install apt-transport-https

# Step 1 — Installing Elasticsearch and Kibana

curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -

echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list

echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list


# Update package lists
sudo apt-get update

# Install ELK Stack (Elasticsearch, Logstash, Kibana)
sudo apt-get install -y default-jre
sudo apt-get install -y elasticsearch logstash kibana filebeat 

# Start ELK Stack services
sudo service elasticsearch start
sudo service logstash start
sudo service kibana start

sudo filebeat modules enable suricata
sudo filebeat modules enable zeek

sudo filebeat setup

sudo systemctl start filebeat.service


# Install Suricata

add-apt-repository ppa:oisf/suricata-stable


sudo apt-get install -y suricata

# Start Suricata service
sudo service suricata start
sudo systemctl enable suricata

# Install Zeek

echo 'deb http://download.opensuse.org/repositories/security:/zeek/xUbuntu_20.10/ /' | sudo tee /etc/apt/sources.list.d/security:zeek.list
curl -fsSL https://download.opensuse.org/repositories/security:zeek/xUbuntu_20.10/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/security_zeek.gpg > /dev/null
apt update

sudo apt-get install -y zeek

# Start Zeek service
sudo zeekctl deploy
sudo zeekctl start

# Add any additional configuration or setup steps as needed

# End of installation script
