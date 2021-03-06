require 'rubygems'
require 'net-ldap'

class Iptables
  def initialize (table)
    @table = table
  end
  
  def append_entry (chain, rule)
    if rule['destination']
      `/sbin/iptables -t #{@table} -A #{chain} #{rule['destination']} -o #{rule['out-interface']} -j #{rule['jump']}`
    else
      `/sbin/iptables -t #{@table} -A #{chain} -s #{rule['source']} -j #{rule['jump']}`
    end
  end
  
  def delete_entry (chain, rule)
    `/sbin/iptables -t #{@table} -D #{chain} -s #{rule['source']} -j #{rule['jump']}`
  end
  
  def create_chain (chain)
    `/sbin/iptables -t #{@table} -N #{chain}`
  end
  
  def flush_entries (chain)
    `/sbin/iptables -t #{@table} -F #{chain}`
  end
  
  def delete_chain (chain)
    `/sbin/iptables -t #{@table} -X #{chain}`
  end
end

class Client
  def initialize (args)
    @ldap_host = args[:ldap_host]
    @ldap_base = args[:ldap_base]
    @ldap_userdn = args[:ldap_userdn]
    @rule_out_inteface = args[:rule_out_inteface] 
    @rule_jump = args[:rule_jump]
    @alter_rule_jump = args[:alter_rule_jump]
    @dns_servers = args[:dns_servers] 
    @user = args[:user]
    @remote_ip = args[:remote_ip]
  end 

  def connect
    ldap = connect_ldap
    destinations = search_routing_groups(ldap)
    add_iptables_rules (destinations)
  end

  def disconnect
    delete_iptables_rules  
  end

private
  def connect_ldap
    ldap = Net::LDAP.new
    ldap.host = @ldap_host
    ldap.bind
    ldap
  end
  
  def search_routing_groups (ldap)
    destinations = []
    filter = "(&(objectclass=groupOfUniqueNames)(uniqueMember=#{@ldap_userdn}))"
    attrs =  ["description"]
    ldap.search(:base => @ldap_base, :filter => filter, :attributes => attrs)  do |entry| 
      entry.description.each do |destination|
        destinations << destination
      end
    end
    destinations 
  end
  
  def add_iptables_rules (destinations)
    delete_iptables_rules
    natt = Iptables.new("nat")
    filtert = Iptables.new("filter")
    puts "Adding new chain #{@remote_ip}"
    natt.create_chain(@remote_ip)
    filtert.create_chain(@remote_ip)
    destinations.each do |destination|
      rule = {
        "source" => @remote_ip,
        "destination" => destination,
        "out-interface" => @rule_out_inteface,
        "jump" => @rule_jump
      }
      natt.append_entry(@remote_ip,rule)
      rule["jump"] = @alter_rule_jump
      filtert.append_entry(@remote_ip,rule)          
    end
    @dns_servers.each do |dns_server|
      rule = {
        "source" => @remote_ip,
        "destination" =>"--destination #{dns_server}",
        "out-interface" => @rule_out_inteface,
        "jump" => @rule_jump
      }
      natt.append_entry(@remote_ip,rule)
      rule["jump"] = @alter_rule_jump
      filtert.append_entry(@remote_ip,rule)  
    end
    natt.append_entry("POSTROUTING", {"source" => @remote_ip, "jump" => @remote_ip}) 
    filtert.append_entry("FORWARD", {"source" => @remote_ip, "jump" => @remote_ip})
  end
 
  def delete_iptables_rules 
    puts "Cleaning up after ourselves"
    natt = Iptables.new("nat")
    natt.delete_entry("POSTROUTING", {"source" => @remote_ip, "jump" => @remote_ip})
    natt.flush_entries(@remote_ip)
    natt.delete_chain(@remote_ip) 
    
    filtert = Iptables.new("filter")
    filtert.delete_entry("FORWARD", {"source" => @remote_ip, "jump" => @remote_ip})
    filtert.flush_entries(@remote_ip)
    filtert.delete_chain(@remote_ip)
  end
end

user = ARGV[0]
remote_ip = ARGV[1]
action = ARGV[2]

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


action == "connect" ? (client.connect) : (client.disconnect)

