# Setup minimal footprint

Based on

https://docs.gitlab.com/omnibus/settings/memory_constrained_envs/

1. First start

2. After base start copy `gitlab.rb` file to storage

```

sudo cp gitlab.rb /mnt/pseudo_disk_0/gitlab_home/config/

Troubles:
Didn't apply, puma alive even all stopped

Need restart of WHOLE system

Trouble:
Can't kill
https://stackoverflow.com/questions/71477749/error-response-from-daemon-cannot-kill-container-permission-denied-how-to-kil

!!! it kills snapd and all programms installed by it
```