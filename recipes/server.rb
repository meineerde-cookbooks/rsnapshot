include_recipe "cron"

package "rsnapshot"

# create the private key if necessary
root_home = Etc.getpwnam("root").dir
directory "#{root_home}/.ssh" do
  owner "root"
  group "root"
  mode "0700"
end

execute "create ssh keypair for root" do
  cwd root_home
  user "root"
  command <<-KEYGEN.gsub(/^ +/, '')
    ssh-keygen -t rsa -b 2048 -f #{root_home}/.ssh/id_rsa -N '' \
    -C 'root@#{node['fqdn']}-#{Time.now.strftime('%FT%T%z')}'
    chmod 0600 #{root_home}/.ssh/id_rsa
    chmod 0644 #{root_home}/.ssh/id_rsa.pub
  KEYGEN
  creates "#{root_home}/.ssh/id_rsa"
end

ruby_block "set public key to node" do
  block do
    node.set['rsnapshsot']['server']['public_key'] = File.read("#{root_home}/.ssh/id_rsa.pub")
  end
end

directory node['rsnapshot']['server']['snapshot_root'] do
  owner "root"
  group "root"
  mode "0700"
end

backup_targets = []
search(:node, "roles:#{node['rsnapshot']['client_role']}") do |client|
  paths = client['rsnapshot']['client']['paths']
  next unless paths && paths.any?

  paths.each do |path|
    path = path.end_with?("/") ? path : "#{path}/"
    if client['fqdn'] == node['fqdn']
      backup_targets << "#{path}/\t#{client['fqdn']}#{path}"
    else
      # FIXME: What about ipv6?
      backup_targets << "#{client['rsnapshot']['client']['username']}@#{client['ipaddress']}:#{path}\t#{client['fqdn']}#{path}"
    end
  end
end
template node['rsnapshot']['server']['config_file'] do
  source "rsnapshot.conf.erb"
  owner "root"
  group "root"
  mode "0644"
  variables "backup_targets" => backup_targets
end

template "/etc/cron.d/rsnapshot" do
  source "cron.erb"
  owner "root"
  group "root"
  mode "0644"
end
