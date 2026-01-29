# File as disk

1. Create file and fill with zeros

```
# For example 10M
sudo dd if=/dev/zero of=/storage.disk bs=1G count=1
sudo mkfs.ext4 /storage.disk

sudo mkdir -p /mnt/pseudo_disk_0/
sudo mount /storage.disk /mnt/pseudo_disk_0/

# TODO() Less right 0766 or something like it
./init_storage.sh
sudo chmod -R 0777 /mnt/pseudo_disk_0/

# Check list of mounted
df -h | grep pseudo_disk_0

# Give something like this
/dev/loop18     5.4M  152K  4.6M   4% /mnt/pseudo_disk_0  # Loop device
```

2. Auto-mounting

```
# Create rc.local if not exist
sudo touch /etc/rc.local
sudo chmod +x /etc/rc.local

sudo nano /etc/rc.local


# Fill with

#!/bin/sh -e

echo "Try to mount"
mount /storage.disk /mnt/pseudo_disk_0/

exit 0
```

```
# Fill systemctl job
sudo nano /lib/systemd/system/rc-local.service

[Unit]
Description=/etc/rc.local Compatibility
Documentation=man:systemd-rc-local-generator(8)
ConditionFileIsExecutable=/etc/rc.local
Before=docker.service containerd.service


[Service]
Type=forking
ExecStart=/etc/rc.local start
TimeoutSec=0
RemainAfterExit=yes
GuessMainPID=no

[Install]
RequiredBy=docker.service containerd.service
```

```
# Umount
sudo umount /mnt/pseudo_disk_0/

# Enable systemctl job
sudo systemctl daemon-reload
sudo systemctl enable rc-local
sudo systemctl start rc-local
sudo systemctl status rc-local
```

3. Reboot and check

```
df -h | grep pseudo_disk_0

# Give something like this
/dev/loop18     5.4M  152K  4.6M   4% /mnt/pseudo_disk_0  # Loop device
```

# S3 storage

1. Select package
```
Variant:
https://github.com/minio/minio - Community Edition version was hardly cut by functionality
But: https://habr.com/ru/companies/ruvds/articles/981790/

Variant:
https://garagehq.deuxfleurs.fr/

# Need run like this, in order to openssl generates keys
# No need to store into git

mkdir creds

cat > creds/garage.toml <<EOF
metadata_dir = "/var/lib/garage/meta"
data_dir = "/var/lib/garage/data"
db_engine = "sqlite"

replication_factor = 1

rpc_bind_addr = "[::]:3901"
rpc_public_addr = "127.0.0.1:3901"
rpc_secret = "$(openssl rand -hex 32)"

[s3_api]
s3_region = "garage"
api_bind_addr = "[::]:3900"
root_domain = ".s3.garage.localhost"

[s3_web]
bind_addr = "[::]:3902"
root_domain = ".web.garage.localhost"
index = "index.html"

[k2v_api]
api_bind_addr = "[::]:3904"

[admin]
api_bind_addr = "[::]:3903"
admin_token = "$(openssl rand -base64 32)"
metrics_token = "$(openssl rand -base64 32)"
EOF

# Check what was generated
cat creds/garage.toml
```
2. Start docker compose

```
docker-compose build
docker-compose up -d

# Maybe docker compose <user cmd>
```

3. Configure cluster (https://garagehq.deuxfleurs.fr/documentation/quick-start/)

```
# Run commands from outside of docker
docker exec -it artifactory /garage status

# Response example
ID                Hostname      Address         Tags  Zone  Capacity          DataAvail  Version
19090f15b867b2e2  eb58e89242b1  127.0.0.1:3901              NO ROLE ASSIGNED             git:v2.1.0


docker exec -it artifactory /garage layout assign -z dc1 -c 100M 2a5f32014e5de6d7
docker exec -it artifactory /garage  layout apply --version 1
docker exec -it artifactory /garage bucket create nextcloud-bucket

# What we have
docker exec -it artifactory /garage bucket list
docker exec -it artifactory /garage bucket info nextcloud-bucket

# Access
docker exec -it artifactory /garage key create nextcloud-app-key
==== ACCESS KEY INFORMATION ====
Key ID:              AAAAAAAA
Key name:            nextcloud-app-key
Secret key:          BBBBBBBB
Created:             2026-01-20 09:03:20.732 +00:00

docker exec -it artifactory /garage bucket allow \
  --read \
  --write \
  --owner \
  nextcloud-bucket \
  --key nextcloud-app-key

docker exec -it artifactory /garage bucket info nextcloud-bucket

# Example response
2026-01-20T08:50:04.546381Z  INFO garage_net::netapp: Connected to 127.0.0.1:3901, negotiating handshake...    
2026-01-20T08:50:04.587326Z  INFO garage_net::netapp: Connection established to 19090f15b867b2e2    
==== BUCKET INFORMATION ====
Bucket:          c845f108c3ae086d4d92b3ce693e66ad4649feaf6ed9d24dd26700b6ba2678c6
Created:         2026-01-20 08:48:00.761 +00:00

Size:            0 B (0 B)
Objects:         0

Website access:  false  # TODO() Give web access

Global alias:    nextcloud-bucket

==== KEYS FOR THIS BUCKET ====
Permissions  Access key                                     Local aliases
RWO          GK801ba4b45db331b4d9181c2c  nextcloud-app-key 
```

4. Access using standart tools

```
# Need install in such way really

# No snap in docker. Can't install in jenkins docker image
sudo snap install aws-cli --channel=v2/stable --classic

export AWS_ACCESS_KEY_ID=AAAAAAAA      # put your Key ID here
export AWS_SECRET_ACCESS_KEY=BBBBBBBB  # put your Secret key here
export AWS_DEFAULT_REGION='garage'
export AWS_ENDPOINT_URL='http://localhost:3900'

# Check
env | grep AWS
aws --version

aws --version
aws-cli/2.33.2 Python/3.13.11 Linux/6.8.0-90-generic exe/x86_64.ubuntu.22

# Usige

# list buckets
aws s3 ls

# list objects of a bucket
aws s3 ls s3://nextcloud-bucket

# copy from your filesystem to garage
# Note: Don't use /proc/* as in tutorial, it produce empty files in storage. No content sent
touch /tmp/my.txt
echo "Hello" > /tmp/my.txt
aws s3 cp /tmp/my.txt s3://nextcloud-bucket/

# copy from garage to your filesystem
aws s3 cp s3://nextcloud-bucket/my.txt /tmp/my-rd.txt

# Enable web for basket. Doesn't work really

docker exec -it artifactory /garage  bucket website --allow nextcloud-bucket

docker exec -it artifactory /garage bucket info nextcloud-bucket
```

5. Gui client

```
https://unixhost.pro/blog/2025/11/webui-for-garage-s3-server/


```

# Monitoring

1. Start Graphana
```
# Need set rights, it's strange
# TODO() Make lower rights
# Warning! Can't create storage at level of docker-compose.yaml. Build will fail
mkdir -p ../storage/grafana
chmod 0777 ../storage/grafana

# Default user:passwrd - admin:admin

Promethous endpoint: http://prometheus:9090  # Name of host in docker network
```

# Jenkins

1. As part of compose

```
https://timeweb.cloud/tutorials/ci-cd/avtomatizaciya-nastrojki-jenkins-s-pomoshchyu-docker

Issues - cli hangs
Fixed: docker compose down && docker compose build

After login
Install Suggested

agent name should match agent name from docker-compose

ALARM! Gaps in tutorial

Didn't get what is jenkins.yaml, it isn't create jobs or pipelines

Hello world is okey
```

# Gitlab

1. Allocate storage

```
mkdir -p ../storage/gitlab_home
chmod 0777 ../storage/gitlab_home
```

# Creating storage file structure

1. From source

```
./init_storage.sh
```

# Private creds

```
cp template_creds.env creds/creds.env

# Put own

docker compose down
docker compose up -d
```

# Docker from docker

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