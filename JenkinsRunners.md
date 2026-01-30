# Only one type of workers for now - Vagrant/ubuntu25.10
1. Disable build in Jenkins runner

2. Create agent and set workspace path to `/vagrant/data`

3. Create work folder

```
sudo mkdir -p /mnt/big_disk/workspace_agent_vm0
sudo chmod 0777 /mnt/big_disk/workspace_agent_vm0 -R
sudo mkdir -p /mnt/big_disk/workspace_agent_vm0/data
sudo chmod 0777 /mnt/big_disk/workspace_agent_vm0/data/ -R
```

4. Install `vagrant` and `virtualbox`
```

Note: Vagrant related artifactories need VPN connection

sudo apt purge "^virtualbox.*"
sudo apt autoremove

curl -fsSL https://www.virtualbox.org/download/oracle_vbox_2016.asc | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/oracle_vbox_2016.gpg
echo "deb [arch=amd64] https://download.virtualbox.org/virtualbox/debian $(lsb_release -sc) contrib" | sudo tee /etc/apt/sources.list.d/virtualbox.list
sudo apt update
sudo apt install virtualbox-7.1 -y
#sudo apt install virtualbox-7.1-dkms --reinstall
sudo usermod -aG vboxusers $USER

# Take vagrant from Yandex.Disk
wget https://gist.githubusercontent.com/Yegorov/dc61c42aa4e89e139cd8248f59af6b3e/raw/20ac954e202fe6a038c2b4bb476703c02fe0df87/ya.py
python3 ya.py https://disk.yandex.ru/d/Rb46K7Oi39jYzw .

# Or using Vpn

wget https://releases.hashicorp.com/vagrant/2.4.9/vagrant_2.4.9-1_amd64.deb

sudo apt purge "^vagrant.*"

sudo dpkg -i vagrant_2.4.9-1_amd64.deb

# May need:
sudo apt purge lvm2 && sudo apt install lvm2 
```

5. Pull vbox and add to vagrant

```
# May need VPN

wget https://vagrantcloud.com/alvistack/boxes/ubuntu-25.10/versions/20260111.1.1/providers/virtualbox/amd64/vagrant.box

or from Yandex.Disk

wget https://gist.githubusercontent.com/Yegorov/dc61c42aa4e89e139cd8248f59af6b3e/raw/20ac954e202fe6a038c2b4bb476703c02fe0df87/ya.py
python3 ya.py https://disk.yandex.ru/d/2aqo0kwrQWlxoQ .

# Or from browser

# Give file like this, no extention - f14d580c-ef35-11f0-adc8-b2f692dae68f

vagrant box add alvistack/ubuntu-25.10 ./f14d580c-ef35-11f0-adc8-b2f692dae68f
```

6. Vagrant work folders

```
cp vangart_templ/Vagrantfile /mnt/big_disk/workspace_agent_vm0
cd /mnt/big_disk/workspace_agent_vm0
```

7. Select shared interface

```
# On host check interfaces

sudo apt install net-tools

ifconfig

...
wlp82s0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 192.168.0.2  netmask 255.255.255.0  broadcast 192.168.0.255
        inet6 fe80::1825:cd30:b638:10eb  prefixlen 64  scopeid 0x20<link>
        ether a8:7e:ea:01:90:f5  txqueuelen 1000  (Ethernet)
        RX packets 8778947  bytes 12660705183 (12.6 GB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 1358823  bytes 174444918 (174.4 MB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

# We have to use Wifi or eth* interface, WLAN

vboxmanage list bridgedifs
```

8. Only now start vm

```
vagrant up

# It ask about interface

May need install newest virtualbox
```

9. Got to VM and configure

```
vagrant ssh
sudo apt update
sudo apt install docker.io net-tools qemu-user default-jre awscli
sudo usermod -aG docker $USER
newgrp docker
docker run hello-world
```

10. Start jenkins agent by hand for now
```
# TODO() Doesn't work really
#cd /vagrant/data
#sudo chown vagrant:vagrant .

# Only helps for Armbian builds

agent folder
/home/vagrant/code/data

export GIT_DISABLE_UNSAFE_DIRECTORIES=1

curl -sO http://192.168.0.6:8080/jnlpJars/agent.jar  # Pull agent from docker, ip of interface below

export AGENT_SECRET=4ace2b1d322554f02325e3fe29b60d3c5b74f2d691bbdac4366fe63fbe3d5990
java -jar agent.jar -url http://192.168.0.2:8080/ -secret $AGENT_SECRET -name nodocker -webSocket -workDir "/vagrant/data"

java -jar agent.jar -url http://192.168.0.6:8080/ -secret 4ace2b1d322554f02325e3fe29b60d3c5b74f2d691bbdac4366fe63fbe3d5990 -name nondocker -webSocket -workDir "/vagrant/data"

```

11. Now agent should be visible in Jenkins

############################### Trash ####################################

# Install plugin
vagrant plugin install vagrant-git

# In Vagrantfile
config.git.safe_directories = ['/vagrant']

# Docker from docker (Possible but for what it means to be - useless)

```
https://community.jenkins.io/t/jenkins-under-docker-with-v-var-run-docker-sock-var-run-docker-sock-permission-denied/1050/2
https://community.jenkins.io/t/jenkins-unable-to-use-docker-agent-in-pipeline/11196/5
https://superuser.com/questions/1428856/docker-in-docker-jenkins-on-ubuntu-permission-issue-with-docker-sock

Magic: user from host machine

sudo gpasswd -a $USER docker
sudo setfacl -m user:$USER:rw /var/run/docker.sock

It works somehow
```

# Big disk to build agent

```
sudo mkdir /mnt/big_disk/workspace_agent_0
sudo chmod 0777 /mnt/big_disk/workspace_agent_0 -R

```

# Build Armbian. Loop devices troubles for in docker agent (Optional)

```
1. (Not working) On own host
[Alarm!] Need host system 24.04 and above

sudo apt install openjdk-17-jdk-headless

sudo update-alternatives --config java
sudo update-alternatives --config javac

curl -sO http://localhost:8080/jnlpJars/agent.jar
java -jar agent.jar -url http://localhost:8080/ -secret XXXXXXXXXXXXXXXXXX -name nodocker -webSocket -workDir "/mnt/big_disk/workspace_agent_1"

Error response from daemon: client version 1.43 is too old. Minimum supported API version is 1.44, please upgrade your client to a newer version: driver not connecting

mkdir -p /mnt/big_disk/workspace_agent_1
./run_nondocker_agent.sh

export DISTRO=$(lsb_release -c | cut -d: -f2 | sed 's/^[ \t]*//')

sudo curl --progress-bar --proto '=https' --tlsv1.2 -Sf https://repo.waydro.id/waydroid.gpg --output /usr/share/keyrings/waydroid.gpg


/etc/apt/sources.list.d/waydroid.list

sudo rm  /etc/apt/sources.list.d/pgadmin4.list*

apt-key adv --refresh-keys --keyserver keyserver.ubuntu.com

# Need for new Armbian bild
sudo ./compile.sh requirements

export DOCKER_API_VERSION=1.44  #????

sudo apt install qemu-system

# Download and run the QEMU registration script
wget https://github.com/qemu/qemu/raw/master/scripts/qemu-binfmt-conf.sh
chmod +x qemu-binfmt-conf.sh
sudo ./qemu-binfmt-conf.sh --qemu-path /usr/bin --qemu-suffix -static --debian
# Then attempt to import the specific format
sudo update-binfmts --import qemu-loongarch64

./compile.sh requirements  # FAILED

./compile.sh BOARD=nanopi-r5c BRANCH=current RELEASE=noble KERNEL_BTF=no BUILD_MINIMAL=yes BUILD_DESKTOP=no \
                        KERNEL_CONFIGURE=no
                        

2. (Working) Special agent on Vagrant

sudo apt install vagrant

May need:

sudo apt purge lvm2 
sudo apt install lvm2 

https://github.com/chef/bento

Download by hand and

https://github.com/alvistack/vagrant-ubuntu

from browser with VPN

https://vagrantcloud.com/alvistack/boxes/ubuntu-25.10/versions/20260111.1.1/providers/virtualbox/amd64/vagrant.box

Move file to here, name may change

# Choose shared adapter
ifconfig # On host

# For host access need some thing like this - for example
wlp82s0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 192.168.0.2  netmask 255.255.255.0  broadcast 192.168.0.255

vagrant box add alvistack/ubuntu-25.10 ./f14d580c-ef35-11f0-adc8-b2f692dae68f
vagrant up  # Ask about interface, choose wifi or another physical of host, need for future, in example - wlp82s0
vagrant ssh
vagrant destroy --force #(Optional)

stop vm before Vagrantfile edition

# Docker in vagrant

https://stackoverflow.com/questions/47415732/best-way-to-install-docker-on-vagrant - Not working

From inside

sudo apt update
sudo apt install docker.io net-tools qemu-user default-jre

# docker postinstall

# Varant access docker compose

# Need share real interface
sudo mkdir /mnt/big_disk
sudo mkdir /mnt/big_disk
sudo chmod 0777 /mnt/big_disk -R

export AGENT_SECRET=xxxxx
curl -sO http://192.168.0.2:8080/jnlpJars/agent.jar  # Pull agent from docker
java -jar agent.jar -url http://192.168.0.2:8080/ -secret $AGENT_SECRET -name nodocker -webSocket -workDir "/mnt/big_disk/workspace_agent_1"

if space of /tmp or disk will be small Jenkins drop this node

```