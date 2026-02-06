# пройти все шаги из Vm.md до configure Cluster (done)

File as disk

    Create file and fill with zeros

# For example 10M
sudo dd if=/dev/zero of=/storage.disk bs=1G count=1
sudo mkfs.ext4 /storage.disk

sudo mkdir -p /mnt/pseudo_disk_0/
sudo mount /storage.disk /mnt/pseudo_disk_0/

# TODO() Less right 0766 or something like it
./init_storage.sh
sudo chmod -R 0777 /mnt/pseudo_disk_0/
sudo chmod -R 0777 /mnt/pseudo_disk_0/grafana/

# Check list of mounted
df -h | grep pseudo_disk_0

# Give something like this
/dev/loop18     5.4M  152K  4.6M   4% /mnt/pseudo_disk_0  # Loop device

    Auto-mounting

# Create rc.local if not exist
sudo touch /etc/rc.local
sudo chmod +x /etc/rc.local

sudo nano /etc/rc.local


# Fill with

#!/bin/sh -e

echo "Try to mount"
mount /storage.disk /mnt/pseudo_disk_0/

exit 0

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

# Umount
sudo umount /mnt/pseudo_disk_0/

# Enable systemctl job
sudo systemctl daemon-reload
sudo systemctl enable rc-local
sudo systemctl start rc-local
sudo systemctl status rc-local

    Reboot and check

df -h | grep pseudo_disk_0

# Give something like this
/dev/loop18     5.4M  152K  4.6M   4% /mnt/pseudo_disk_0  # Loop device
