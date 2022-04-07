### Script originally based on https://gist.github.com/kydouglas/1f68d69e856fd6d7dc223f8e1f5ae3b3
#!/bin/bash

#ONE LINE
#sudo wget -Nnv 'https://gist.githubusercontent.com/kydouglas/1f68d69e856fd6d7dc223f8e1f5ae3b3/raw/f8c3b22b9d9c41093150b96c815776956b523d9d/elk.sh' && bash elk.sh && rm -f elk.sh

# Checking whether user has enough permission to run this script
sudo -n true
if [ $? -ne 0 ]
    then
        echo "This script requires user to have passwordless sudo access"
        exit
fi

dependency_check_deb() {
java -version
if [ $? -ne 0 ]
    then
        # Installing Java 8 if it's not installed
        sudo apt-get install openjdk-8-jre-headless -y
    # Checking if java installed is less than version 7. If yes, installing Java 7. As logstash & Elasticsearch require Java 7 or later.
    elif [ "`java -version 2> /tmp/version && awk '/version/ { gsub(/"/, "", $NF); print ( $NF < 1.8 ) ? "YES" : "NO" }' /tmp/version`" == "YES" ]
        then
            sudo apt-get install openjdk-8-jre-headless -y
fi
}

debian_elk() {
    # install firewall and nginx
    sudo apt install ufw nginx
    sudo ufw allow 22/tcp
    sudo ufw enable
    sudo systemctl enable nginx
    sudo systemctl start nginx
    # add public GPGP key
    wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
    # add elastic to source list
    echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list
    # resynchronize the package index files from their sources.
    sudo apt-get update
    # install elasticsearch
    sudo apt install elasticsearch
    # change configuration
    sudo sed -i 's/^ *# *network.host: *[^ ]*/network.host: localhost/' /etc/elasticsearch/elasticsearch.yml
    # start service
    sudo systemctl start elasticsearch
    # enable service
    sudo systemctl enable elasticsearch
    # test connection
    curl -X GET "localhost:9200"
    # install kibana
    sudo apt install kibana
    # start service
    sudo systemctl start kibana
    # enable service
    sudo systemctl enable kibana
    # create admin
    echo "kibanaadmin:`openssl passwd -apr1`" | sudo tee -a /etc/nginx/htpasswd.users
    # configure reverse-proxy
    sudo tee /etc/nginx/sites-available/elk.connecttvnowcom.com > /dev/null <<EOT
server {
    listen 80;

    server_name elk.connecttvnowcom.com;

    auth_basic "Restricted Access";
    auth_basic_user_file /etc/nginx/htpasswd.users;

    location / {
        proxy_pass http://localhost:5601;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOT
    # symlink
    sudo ln -s /etc/nginx/sites-available/elk.connecttvnowcom.com /etc/nginx/sites-enabled/elk.connecttvnowcom.com
    # test nginx
    sudo nginx -t
    # restart nginx
    sudo systemctl restart nginx
    # open ports in UFW
    sudo ufw allow 'Nginx Full'
    # install logstash
    sudo apt install logstash
    # configurations
    sudo tee /etc/logstash/conf.d/02-beats-input.conf > /dev/null <<EOT
input {
  beats {
    port => 5044
  }
}
EOT
    sudo tee /etc/logstash/conf.d/10-syslog-filter.conf > /dev/null <<EOT
filter {
  if [fileset][module] == "system" {
    if [fileset][name] == "auth" {
      grok {
        match => { "message" => ["%{SYSLOGTIMESTAMP:[system][auth][timestamp]} %{SYSLOGHOST:[system][auth][hostname]} sshd(?:\[%{POSINT:[system][auth][pid]}\])?: %{DATA:[system][auth][ssh][event]} %{DATA:[system][auth][ssh][method]} for (invalid user )?%{DATA:[system][auth][user]} from %{IPORHOST:[system][auth][ssh][ip]} port %{NUMBER:[system][auth][ssh][port]} ssh2(: %{GREEDYDATA:[system][auth][ssh][signature]})?",
                  "%{SYSLOGTIMESTAMP:[system][auth][timestamp]} %{SYSLOGHOST:[system][auth][hostname]} sshd(?:\[%{POSINT:[system][auth][pid]}\])?: %{DATA:[system][auth][ssh][event]} user %{DATA:[system][auth][user]} from %{IPORHOST:[system][auth][ssh][ip]}",
                  "%{SYSLOGTIMESTAMP:[system][auth][timestamp]} %{SYSLOGHOST:[system][auth][hostname]} sshd(?:\[%{POSINT:[system][auth][pid]}\])?: Did not receive identification string from %{IPORHOST:[system][auth][ssh][dropped_ip]}",
                  "%{SYSLOGTIMESTAMP:[system][auth][timestamp]} %{SYSLOGHOST:[system][auth][hostname]} sudo(?:\[%{POSINT:[system][auth][pid]}\])?: \s*%{DATA:[system][auth][user]} :( %{DATA:[system][auth][sudo][error]} ;)? TTY=%{DATA:[system][auth][sudo][tty]} ; PWD=%{DATA:[system][auth][sudo][pwd]} ; USER=%{DATA:[system][auth][sudo][user]} ; COMMAND=%{GREEDYDATA:[system][auth][sudo][command]}",
                  "%{SYSLOGTIMESTAMP:[system][auth][timestamp]} %{SYSLOGHOST:[system][auth][hostname]} groupadd(?:\[%{POSINT:[system][auth][pid]}\])?: new group: name=%{DATA:system.auth.groupadd.name}, GID=%{NUMBER:system.auth.groupadd.gid}",
                  "%{SYSLOGTIMESTAMP:[system][auth][timestamp]} %{SYSLOGHOST:[system][auth][hostname]} useradd(?:\[%{POSINT:[system][auth][pid]}\])?: new user: name=%{DATA:[system][auth][user][add][name]}, UID=%{NUMBER:[system][auth][user][add][uid]}, GID=%{NUMBER:[system][auth][user][add][gid]}, home=%{DATA:[system][auth][user][add][home]}, shell=%{DATA:[system][auth][user][add][shell]}$",
                  "%{SYSLOGTIMESTAMP:[system][auth][timestamp]} %{SYSLOGHOST:[system][auth][hostname]} %{DATA:[system][auth][program]}(?:\[%{POSINT:[system][auth][pid]}\])?: %{GREEDYMULTILINE:[system][auth][message]}"] }
        pattern_definitions => {
          "GREEDYMULTILINE"=> "(.|\n)*"
        }
        remove_field => "message"
      }
      date {
        match => [ "[system][auth][timestamp]", "MMM  d HH:mm:ss", "MMM dd HH:mm:ss" ]
      }
      geoip {
        source => "[system][auth][ssh][ip]"
        target => "[system][auth][ssh][geoip]"
      }
    }
    else if [fileset][name] == "syslog" {
      grok {
        match => { "message" => ["%{SYSLOGTIMESTAMP:[system][syslog][timestamp]} %{SYSLOGHOST:[system][syslog][hostname]} %{DATA:[system][syslog][program]}(?:\[%{POSINT:[system][syslog][pid]}\])?: %{GREEDYMULTILINE:[system][syslog][message]}"] }
        pattern_definitions => { "GREEDYMULTILINE" => "(.|\n)*" }
        remove_field => "message"
      }
      date {
        match => [ "[system][syslog][timestamp]", "MMM  d HH:mm:ss", "MMM dd HH:mm:ss" ]
      }
    }
  }
}
EOT
    sudo tee /etc/logstash/conf.d/30-elasticsearch-output.conf > /dev/null <<EOT
output {
  elasticsearch {
    hosts => ["localhost:9200"]
    manage_template => false
    index => "%{[@metadata][beat]}-%{[@metadata][version]}-%{+YYYY.MM.dd}"
  }
}
EOT
    # test logstash
    sudo -u logstash /usr/share/logstash/bin/logstash --path.settings /etc/logstash -t
    sudo systemctl start logstash
    sudo systemctl enable logstash
    sudo apt install filebeat
    sudo sed -i 's/^ *output.elasticsearch: *[^ ]*/#output.elasticsearch:/' /etc/filebeat/filebeat.yml
    sudo sed -i 's/^ *hosts: *[^ ]*/  #hosts: /' /etc/filebeat/filebeat.yml
    sudo sed -i 's/^ *# *output.logstash: *[^ ]*/output.logstash:/' /etc/filebeat/filebeat.yml
    sudo sed -i 's/^ *# *hosts: *[^ ]*/  hosts: ["localhost:5044"]/' /etc/filebeat/filebeat.yml
    sudo filebeat modules enable system
    sudo filebeat modules list
    sudo filebeat setup --index-management -E output.logstash.enabled=false -E 'output.elasticsearch.hosts=["localhost:9200"]'
    sudo filebeat setup -e -E output.logstash.enabled=false -E output.elasticsearch.hosts=['localhost:9200'] -E setup.kibana.host=localhost:5601
    sudo systemctl start filebeat
    sudo systemctl enable filebeat
    curl -XGET 'http://localhost:9200/filebeat-*/_search?pretty'
}

# Installing ELK Stack
if [ "$(grep -Ei 'debian|buntu|mint' /etc/*release)" ]
    then
        echo " It's a Debian based system"
        dependency_check_deb
        debian_elk
else
    echo "This script doesn't support ELK installation on this OS."
fi