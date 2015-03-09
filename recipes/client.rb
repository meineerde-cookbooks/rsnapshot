include_recipe 'openssh'
include_recipe 'sudo'

package 'rsync'

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

template '/usr/local/bin/rsnapshot-rsync' do
  source "rsnapshot-rsync.erb"
  owner 'root'
  group 'root'
  mode '0755'
end

sudo 'rsnapshot' do
  user node['rsnapshot']['client']['user']
  commands '/usr/bin/rsync'
  runas 'root'
  nopasswd true
end

directory "~#{node['rsnapshot']['client']['user']}/.ssh" do
  path lazy { File.join node['etc']['passwd'][node['rsnapshot']['client']['user']]['dir'], '.ssh' }

  owner node['rsnapshot']['client']['user']
  group node['rsnapshot']['client']['user']
  mode '0700'

  only_if { node['rsnapshot']['client']['manage_authorized_keys'] }
end

file "~#{node['rsnapshot']['client']['user']}/.ssh/authorized_keys" do
  extend Rsnapshot::RecipeHelpers

  path { File.join node['etc']['passwd'][node['rsnapshot']['client']['user']]['dir'], '.ssh', 'authorized_keys' }
  content rsnapshot_server_keys.sort.join('\n')

  owner node['rsnapshot']['client']['user']
  group node['rsnapshot']['client']['user']
  mode '0400'

  only_if { node['rsnapshot']['client']['manage_authorized_keys'] }
end
