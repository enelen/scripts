#Dynamically creation of iptables rules for opevpn gateway based on ldap group membership.

##Openvpn server config
Openvpn server can run custom scripts when client connects/disconnects.

Add next lines to the openvpn server config:
```
client-connect /opt/openvpn/connect_openvpn_iptables.sh
client-disconnect /opt/openvpn/disconnect_openvpn_iptables.sh
keepalive 10 60
```
Create next files:

/opt/openvpn/connect_openvpn_iptables.sh
```bash
#!/bin/bash
ruby /opt/openvpn/connect_openvpn_iptables.rb $common_name $ifconfig_pool_remote_ip connect
```
/opt/openvpn/disconnect_openvpn_iptables.sh
```bash
#!/bin/bash
ruby /opt/openvpn/connect_openvpn_iptables.rb $common_name $ifconfig_pool_remote_ip disconnect
```
And put connect_openvpn_iptables.rb to /opt/openvpn



##Main script
/opt/openvpn/connect_openvpn_iptables.rb is main script

Edit next lines in this script according you environment: 
```ruby
client = Client.new(
  :user => user,
  :remote_ip => remote_ip,
  :ldap_host => "ldap.helios.me",
  :ldap_base => "ou=RoutingGroups,ou=apps,dc=helios,dc=me",
  :ldap_userdn => "uid=#{user},ou=people,dc=helios,dc=me",
  :rule_out_inteface => "eth0", 
  :rule_jump => "MASQUERADE",
  :alter_rule_jump => "ACCEPT",
  :dns_servers => ["10.10.0.35","10.10.1.35"] ) 
```

After client's connection this script binds to the ldap service.
Based on client's certificate common name (it should match ldap uid) it search in ldap
groups client belongs to.
In this groups we have description attribute that specifies iptables rule (i.e. - --destination 10.128.32.76/32).
Each group can have few description attributes. 
Each client can belongs to few groups.
Script get this rules and create iptables chain named by client's ip. 
Also it creates rule that forward all client traffic to this chain and add this rules to this chain.
You can also specify dns servers in script to allow access to it for all clients.
When client disconnects it removes this chain and rules in 60 seconds - ( keepalive 10 60 directive in server.conf)
