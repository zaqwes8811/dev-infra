1. Gitlab runner subsystem going mad and will whole partition with logs, can't be fixed by change logging of container

2. Jenkins hangs after plugins installing

```
# Recreate home folder
docker-compose down
ls /mnt/pseudo_disk_0/
rm -rf /mnt/pseudo_disk_0/jenkins_home
mkdir /mnt/pseudo_disk_0/jenkins_home
```