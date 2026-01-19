# File as disk

1. Create file and fill with zeros

```
# For example 10M
sudo dd if=/dev/zero of=/storage.disk bs=1M count=10
sudo mkfs.ext4 /storage.disk

sudo mkdir -p /mnt/pseudo_disk_0/
sudo mount /storage.disk /mnt/pseudo_disk_0/

# TODO() Less right 0766 or something like it
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
metadata_dir = "/tmp/meta"
data_dir = "/tmp/data"
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

sudo snap install aws-cli --channel=v2/stable --classic

python3 -m pip install --user awscli

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
aws s3 cp /proc/cpuinfo s3://nextcloud-bucket/cpuinfo.txt

# copy from garage to your filesystem
aws s3 cp s3://nextcloud-bucket/cpuinfo.txt /tmp/cpuinfo.txt

# Enable web for basket. Doesn't work really

docker exec -it artifactory /garage  bucket website --allow nextcloud-bucket

docker exec -it artifactory /garage bucket info nextcloud-bucket
```

5. Gui client

```
https://unixhost.pro/blog/2025/11/webui-for-garage-s3-server/


```