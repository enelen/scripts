#Juniper configuration backup script

##Idea
Juniper switches can send config file to remote server after each commit. We will use scp for it.
Backups will be stored at /home/juniper/<switch hostname>

##Configuration

Run next command on switch in freebsd mode (it should be % in prompt) -
```
mkdir .ssh
chmod 0700 .ssh/
cd .ssh/
ssh-keygen
scp juniper@<your server IP>:/home/juniper/id_rsa .
scp juniper@<your server IP>:/home/juniper/id_rsa.pub .
```
Then go to the switch configuration
```
cli
edit 

set security ssh-known-hosts fetch-from-server <your server IP>
set system archival configuration transfer-on-commit
set system archival configuration archive-sites "scp://juniper@<your server IP>:/home/juniper/<switch hostname>"
```
You should create /home/juniper/\<switch hostname\> on your server and add juniper_git_backup.rb script to cron.





