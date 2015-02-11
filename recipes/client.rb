include_recipe "rsync"
include_recipe "openssh"
include_recipe "sudo"

user node['rsnapshot']['client']['user'] do
  comment 'rsnapshot backup'
  system true
  shell '/bin/sh'

  home "/home/#{node['rsnapshot']['client']['user']}"
  supports({:manage_home => true})

  only_if { node['rsnapshot']['client']['create_user'] }
  notifies :reload, 'ohai[reload users for rsnapshot]'
end

ohai 'reload users for rsnapshot' do
  action :nothing
  plugin 'etc'
end

directory "/home/#{node['rsnapshot']['client']['user']}/.ssh" do
  owner node['rsnapshot']['client']['user']
  group node['rsnapshot']['client']['user']
  mode "0700"
end

cookbook_file "/home/#{node['rsnapshot']['client']['user']}/.ssh/validate-command.sh" do
  source "validate-command.sh"
  owner "root"
  group "root"
  mode "0755"
end

sudo_d 'rsnapshot' do
  user node['rsnapshot']['client']['user']
  commands node['rsnapshot']['client']['rsync_path']
  runas 'root'
  nopasswd true
end

ssh_keys = []
search(:node, "roles:#{node['rsnapshot']['server_role']} AND rsnapshot_server_ssh_key:* NOT name:#{node.name}") do |server|
  prefix = "from=\"#{server['ipaddress']}\",command=\"/home/#{node['rsnapshot']['client']['user']}/.ssh/validate-command.sh\",no-port-forwarding,no-X11-forwarding,no-agent-forwarding,no-pty"
  ssh_keys << "#{prefix} #{server['rsnapshot']['server']['ssh_key']}"
end

template "/home/#{node['rsnapshot']['client']['user']}/.ssh/authorized_keys" do
  source "authorized_keys.erb"
  owner node['rsnapshot']['client']['user']
  group node['rsnapshot']['client']['user']
  mode "0400"
  variables(
    :ssh_keys => ssh_keys
  )
end
