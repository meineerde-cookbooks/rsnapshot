include_recipe 'cron'

package 'rsnapshot'

# create the private key if necessary
root_home = node['etc']['passwd']['root']['dir']
directory "#{root_home}/.ssh" do
  owner "root"
  group "root"
  mode "0700"
end

bash "create ssh keypair for root" do
  cwd root_home
  user "root"
  command <<-BASH
    set -e
    ssh-keygen -t rsa -b 2048 -f "#{root_home}/.ssh/id_rsa" -N '' -C "root@#{node['fqdn']}-#{Time.now.strftime('%FT%T%z')}"
    chmod 0600 #{root_home}/.ssh/id_rsa
    chmod 0644 #{root_home}/.ssh/id_rsa.pub
  BASH
  creates "#{root_home}/.ssh/id_rsa"
end

ruby_block "save ssh public key of root" do
  block do
    node['rsnapshot']['server']['ssh_key'] = File.read("#{root_home}/.ssh/id_rsa.pub").strip
  end
end

directory node['rsnapshot']['server']['snapshot_root'] do
  owner "root"
  group "root"
  mode "0700"
end

backup_targets = []
node['rsnapshot']['server']['clients'].each_pair do |fqdn, paths|
  Array(paths).each do |path|
    path = path.end_with?("/") ? Shellwords.escape(path) : "#{Shellwords.escape(path)}/"
    backup_targets << "#{node['rsnapshot']['client']['user']}@#{fqdn}:#{path}\t#{fqdn}/"
  end
end

search(:node, node['rsnapshot']['client_search']) do |client|
  next unless client['rsnapshot'] && client['rsnapshot']['client'] && paths = client['rsnapshot']['client']['paths']
  next unless paths.any?

  paths.each do |path|
    path = path.end_with?("/") ? Shellwords.escape(path) : "#{Shellwords.escape(path)}/"
    if client.name == node.name
      backup_targets << "#{path}\t#{client['fqdn']}/"
    else
      backup_targets << "#{client['rsnapshot']['client']['user']}@#{client['ipaddress']}:#{path}\t#{client['fqdn']}/"
    end
  end
end

template node['rsnapshot']['server']['config_file'] do
  source "rsnapshot.conf.erb"
  owner "root"
  group "root"
  mode "0644"
  variables "backup_targets" => backup_targets,
            "ssh_key_location" => "#{root_home}/.ssh/id_rsa"
end

template "/etc/cron.d/rsnapshot" do
  source "cron.erb"
  owner "root"
  group "root"
  mode "0644"
end
