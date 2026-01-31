# Only one type of workers for now - Vagrant/ubuntu25.10
1. Disable build in Jenkins runner

2. Create agent and set workspace path to `/vagrant/data`

3. Create shared work folder

```
sudo mkdir -p /mnt/big_disk/workspace_agent_vm0
sudo chmod 0777 /mnt/big_disk/workspace_agent_vm0 -R
sudo mkdir -p /mnt/big_disk/workspace_agent_vm0/data
sudo chmod 0777 /mnt/big_disk/workspace_agent_vm0/data/ -R

not for agent, too much troubles with git
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
sudo apt install docker.io net-tools qemu-user default-jre awscli tmux
sudo usermod -aG docker $USER
newgrp docker
docker run hello-world
```

10. Start jenkins agent by hand for now from `tmux`
```

add aws variables

agent work folder
Warning! It inside of vm, non shared folder. Too much troubles with it
/home/vagrant/

curl -sO http://192.168.0.6:8080/jnlpJars/agent.jar  # Pull agent from docker, ip of interface below

export AGENT_SECRET=4ace2b1d322554f02325e3fe29b60d3c5b74f2d691bbdac4366fe63fbe3d5990
java -jar agent.jar -url http://192.168.0.2:8080/ -secret $AGENT_SECRET -name nodocker -webSocket -workDir "/home/vagrant/"

# tmux session, allows to off ssh session

tmux new-session -s jenkins-agent

java -jar agent.jar -url http://192.168.0.6:8080/ -secret 30bfb2fbb58f541b258dc8c9a10def5b7f4c4eaf67cf1890a16c8a9c60310e69 -name nondocker -webSocket -workDir "/home/vagrant/"

java -jar agent.jar -url http://192.168.0.2:8080/ -secret 30bfb2fbb58f541b258dc8c9a10def5b7f4c4eaf67cf1890a16c8a9c60310e69 -name nodocker -webSocket -workDir "/home/vagrant"

# connect to current session
tmux a

```

11. Now agent should be visible in Jenkins
