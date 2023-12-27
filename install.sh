#!/bin/bash


sudo apt install git -y


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
# Define URLs for the raw configuration files from GitHub\n
        ELASTICSEARCH_CONFIG_URL='https://raw.githubusercontent.com/user/repo/branch/path/to/elasticsearch.yml'
        ZEEK_CONFIG_URL='https://raw.githubusercontent.com/user/repo/branch/path/to/zeek/node.cfg'
        SURICATA_CONFIG_URL='https://raw.githubusercontent.com/user/repo/branch/path/to/suricata/suricata.yaml'
        LOGSTASH_CONFIG_URL='https://raw.githubusercontent.com/user/repo/branch/path/to/logstash/logstash.conf'
        KIBANA_CONFIG_URL='https://raw.githubusercontent.com/user/repo/branch/path/to/kibana/kibana.yml'
        # Download and replace the Elasticsearch configuration file\n
        curl -o /etc/elasticsearch/elasticsearch.yml $ELASTICSEARCH_CONFIG_URL
        # Download and replace the Zeek configuration file\n
        curl -o /usr/local/zeek/etc/node.cfg $ZEEK_CONFIG_URL
        # Download and replace the Suricata configuration file\n
        curl -o /etc/suricata/suricata.yaml $SURICATA_CONFIG_URL
 # Download and replace the Logstash configuration file\n
        curl -o /etc/logstash/conf.d/logstash.conf $LOGSTASH_CONFIG_URL
        # Download and replace the Kibana configuration file\n
        curl -o /etc/kibana/kibana.yml $KIBANA_CONFIG_URL
        # Restart services to apply new configurations\n
# End of installation script
# Restart services to apply new configurations\n
        sudo systemctl restart elasticsearch\n
        sudo systemctl restart kibana\n
        sudo systemctl restart logstash\n
        sudo zeekctl restart\n
        sudo systemctl restart suricata\n
