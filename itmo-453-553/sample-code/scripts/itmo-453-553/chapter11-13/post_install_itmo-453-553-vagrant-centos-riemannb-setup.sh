#!/bin/bash 
set -e
set -v

# Install base dependencies -  Centos 7 mininal needs the EPEL repo in the line above and the package daemonize
sudo yum update -y
sudo yum install -y wget unzip vim git 

# http://superuser.com/questions/196848/how-do-i-create-an-administrator-user-on-ubuntu
# http://unix.stackexchange.com/questions/1416/redirecting-stdout-to-a-file-you-dont-have-write-permission-on
# This line assumes the user you created in the preseed directory is vagrant
echo "%admin  ALL=NOPASSWD: ALL" | sudo tee -a /etc/sudoers.d/init-users
sudo groupadd admin
sudo usermod -a -G admin vagrant

# Installing Vagrant keys
wget --no-check-certificate 'https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub'
sudo mkdir -p /home/vagrant/.ssh
sudo chown -R vagrant:vagrant /home/vagrant/.ssh
cat ./vagrant.pub >> /home/vagrant/.ssh/authorized_keys
sudo chown -R vagrant:vagrant /home/vagrant/.ssh/authorized_keys
echo "All Done!"

##################################################
# Add User customizations below here
##################################################
##################################################
# Change hostname and /etc/hosts
##################################################
cat << EOT >> /etc/hosts
# Nodes
192.168.33.110 riemanna riemanna.example.com
192.168.33.120 riemannb riemannb.example.com
192.168.33.100 riemannmc riemannmc.example.com
192.168.33.210 graphitea graphitea.example.com
192.168.33.220 graphiteb graphiteb.example.com
192.168.33.200 graphitemc graphitemc.example.com
192.168.33.150 ela1 ela1.example.com
192.168.33.160 ela2 ela2.example.com
192.168.33.170 ela3 ela3.example.com
192.168.33.180 logstash logstash.example.com
192.168.33.10 host1 host1.example.com
192.168.33.11 host2 host2.example.com
192.168.33.190 tornado-proxy torndao-proxy.example.com
192.168.33.191 tornado-web1 torndao-web1.example.com
192.168.33.192 tornado-web2 torndao-web2.example.com
192.168.33.193 tornado-api1 torndao-api1.example.com
192.168.33.194 tornado-api2 torndao-api2.example.com
192.168.33.195 tornado-db torndao-db.example.com
192.168.33.196 tornado-redis torndao-redis.example.com
192.168.33.140 docker1 docker1.example.com
EOT

sudo hostnamectl set-hostname riemannb

##################################################
# Due to needing a tty to run sudo, this install command adds all the pre-reqs to build the virtualbox additions
sudo yum install -y kernel-devel-`uname -r` gcc binutils make perl bzip2 vim wget git rsync
###############################################################################################################
# firewalld additions to make CentOS and riemann to work
###############################################################################################################
# Adding firewall rules for riemann - Centos 7 uses firewalld (Thanks Lennart...)
# http://serverfault.com/questions/616435/centos-7-firewall-configuration
# Websockets are TCP... for now - http://stackoverflow.com/questions/4657033/javascript-websockets-with-udp
sudo systemctl enable firewalld
sudo systemctl start firewalld
sudo firewall-cmd --permanent --zone=public --add-port=5555/tcp --permanent
sudo firewall-cmd --permanent --zone=public --add-port=5556/udp --permanent
sudo firewall-cmd --permanent --zone=public --add-port=5557/tcp --permanent
sudo firewall-cmd --permanent --zone=public --add-port=8888/tcp --permanent
sudo firewall-cmd --permanent --zone=public --add-port=3000/tcp --permanent
sudo firewall-cmd --reload
###############################################################################################################
# Installing epel-release
# P. 128 - 129
sudo yum install -y epel-release
sudo yum install -y java-1.8.0-openjdk-headless.x86_64
###############################################################################################################
# Fetch and install the Riemann RPM
###############################################################################################################
wget https://github.com/riemann/riemann/releases/download/0.3.5/riemann-0.3.5-1.noarch-EL7.rpm
sudo rpm -Uvh riemann-0.3.5-1.noarch-EL7.rpm

# cloning source code examples for the book
git clone https://github.com/turnbullpress/aom-code.git

sudo cp -v /home/vagrant/aom-code/5-6/riemann/riemann.config /etc/riemann
sudo cp -rv /home/vagrant/aom-code/5-6/riemann/examplecom /etc/riemann

sudo sed -i 's/graphitea/graphiteb/g' /etc/riemann/examplecom/etc/graphite.clj
sudo sed -i 's/productiona/productionb/g' /etc/riemann/examplecom/etc/graphite.clj

# Install leiningen on Centos 7 - needed for riemann syntax checker
wget https://raw.githubusercontent.com/technomancy/leiningen/stable/bin/lein
chmod +x lein
sudo cp -v ./lein /usr/local/bin

# Riemann syntax checker download and install
git clone https://github.com/samn/riemann-syntax-check
cd riemann-syntax-check
/usr/local/bin/lein uberjar

# P. 44  Install ruby gem tool, Centos 7 has Ruby 2.x as the default
sudo yum install -y ruby ruby-devel gcc libxml2-devel
sudo gem install --no-ri --no-rdoc riemann-tools

# Enable to Riemann service to start on boot and start the service
sudo systemctl enable riemann
sudo systemctl start riemann

echo "All Done!"