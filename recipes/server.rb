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
  code <<-BASH
    set -e
    ssh-keygen -t rsa -b 2048 -f "#{root_home}/.ssh/id_rsa" -N '' -C "root@#{node['fqdn']}-#{Time.now.strftime('%FT%T%z')}"
    chmod 0600 #{root_home}/.ssh/id_rsa
    chmod 0644 #{root_home}/.ssh/id_rsa.pub
  BASH
  creates "#{root_home}/.ssh/id_rsa"
end

ruby_block "store rsnapshot ssh key" do
  block do
    node.set['rsnapshot']['server']['ssh_key'] = File.read("#{root_home}/.ssh/id_rsa.pub").strip
  end
end

template '/usr/local/sbin/rsnapshot-ssh' do
  source 'rsnapshot-ssh.erb'
  owner 'root'
  group 'root'
  mode '0755'
end

directory node['rsnapshot']['server']['config']['snapshot_root'] do
  owner "root"
  group "root"
  mode "0700"
end

backup_targets = []
ssh_host_config = {}
node['rsnapshot']['server']['clients'].each_pair do |fqdn, client|
  user = client['user'] || node['rsnapshot']['client']['user']
  Array(client['backup_paths']).each do |path|
    path = path.end_with?("/") ? Shellwords.escape(path) : "#{Shellwords.escape(path)}/"
    if fqdn == node.name
      backup_targets << "#{path}\t#{fqdn}/"
    else
      backup_targets << "#{user}@#{client['ipaddress'] || fqdn}:#{path}\t#{fqdn}/"
    end
  end

  if client['ssh_config'] && client['ssh_config'].any?
    key = client['ipaddress'] || fqdn
    ssh_host_config[key] = (ssh_host_config[key] || {}).merge client['ssh_config']
  end
end

search(:node, node['rsnapshot']['server']['client_search']) do |client|
  next unless client['rsnapshot'] && client['rsnapshot']['client'] && backup_paths = client['rsnapshot']['client']['backup_paths']
  next unless backup_paths.any?

  client_ip_attr = node['rsnapshot']['server']['client_search_ip'] || 'ipaddress'
  client_ip = client_ip_attr.split('/').inject(client){ |hash, attr| hash[attr] }

  backup_paths.each do |path|
    path = path.end_with?("/") ? Shellwords.escape(path) : "#{Shellwords.escape(path)}/"
    if client.name == node.name
      backup_targets << "#{path}\t#{client['fqdn']}/"
    else
      backup_targets << "#{client['rsnapshot']['client']['user']}@#{client_ip}:#{path}\t#{client['fqdn']}/"
    end
  end

  if client['rsnapshot']['client']['ssh_config'] && client['rsnapshot']['client']['ssh_config'].any?
    ssh_host_config[client['ipaddress']] = (ssh_host_config[client['ipaddress']] || {}).merge client['rsnapshot']['client']['ssh_config']
  end
end if node['rsnapshot']['server']['client_search']

template "#{root_home}/.ssh/rsnapshot_config" do
  source 'ssh_config.erb'
  owner 'root'
  group 'root'
  mode '0644'

  variables :ssh_config => node['rsnapshot']['server']['ssh_config'],
            :host_config => ssh_host_config
end

template node['rsnapshot']['server']['config_file'] do
  source "rsnapshot.conf.erb"
  owner "root"
  group "root"
  mode "0644"
  variables "backup_targets" => backup_targets.sort
end

need_to_perform_sync = (node['rsnapshot']['server']['config']['sync_first'].to_s == '1')

nice = []
nice << "/usr/bin/nice -n #{node['rsnapshot']['server']['rsnapshot_nice']} --" if node['rsnapshot']['server']['rsnapshot_nice']
nice << "/usr/bin/ionice -c #{node['rsnapshot']['server']['rsnapshot_ionice']} --" if node['rsnapshot']['server']['rsnapshot_ionice']
nice = nice.join(' ')

sync_command = [
  node['rsnapshot']['server']['commands']['before_sync'],
  "#{nice} #{node['rsnapshot']['server']['commands']['sync']}".strip
].compact.join('; ')

node['rsnapshot']['server']['retain'].each do |interval|
  if node['rsnapshot']['server']['intervals'][interval.to_s]['keep'].to_i > 0
    cron_d "rsnapshot_#{interval}" do
      hour node['rsnapshot']['server']['intervals'][interval.to_s]['cron']['hour']
      minute node['rsnapshot']['server']['intervals'][interval.to_s]['cron']['minute']
      day node['rsnapshot']['server']['intervals'][interval.to_s]['cron']['day']
      month node['rsnapshot']['server']['intervals'][interval.to_s]['cron']['month']
      weekday node['rsnapshot']['server']['intervals'][interval.to_s]['cron']['weekday']

      user 'root'
      mailto node['rsnapshot']['server']['intervals'][interval.to_s]['cron']['mailto']

      rotate_cmd = [
        node['rsnapshot']['server']['intervals'][interval.to_s]['before_rotate'],
        "#{nice} #{node['rsnapshot']['server']['commands']['rsnapshot']} #{interval.to_s}".strip,
        node['rsnapshot']['server']['intervals'][interval.to_s]['after_rotate']
      ].compact.join(' && ')
      if need_to_perform_sync
        need_to_perform_sync = false
        if node['rsnapshot']['server']['abort_rotate_on_sync_error']
          cmd = "#{sync_command}; [ $? -eq 1 ] && echo 'Aborting rsnapshot rotation due to previous sync error.' >&2 || #{rotate_cmd}"
        else
          cmd = "#{sync_command}; #{rotate_cmd}"
        end
      else
        cmd = rotate_cmd
      end
      command cmd
    end
  else
    cron_d "rsnapshot_#{interval}" do
      action :delete
    end
  end
end
