module Rsnapshot
  module RecipeHelpers
    def rsnapshot_server_keys(options=%w[no-port-forwarding no-X11-forwarding no-agent-forwarding no-pty])
      ssh_keys = []

      node['rsnapshot']['client']['servers'].each do |server_ip, ssh_key|
        prefix  = ["command=\"/usr/local/bin/rsnapshot-rsync\""]
        prefix << "from=\"#{server_ip}\""
        prefix += options.map{|opt| opt.to_s.strip }

        ssh_keys << "#{prefix.join(',')} #{ssh_key}"
      end

      search(:node, "#{node['rsnapshot']['client']['server_search']} AND rsnapshot_server_ssh_key:* NOT name:#{node.name}") do |server|
        next unless server['rsnapshot'] && server['rsnapshot']['server'] && server['rsnapshot']['server']['ssh_key']

        server_ip = node['rsnapshot']['client']['server_search_ip'].split('/').inject(server){ |hash, attr| hash[attr] }

        prefix  = ["command=\"/usr/local/bin/rsnapshot-rsync\""]
        prefix << "from=\"#{Array(server_ip).join(',')}\"" if Array(server_ip).any?
        prefix += options.map{|opt| opt.to_s.strip }

        ssh_keys << "#{prefix.join(',')} #{server['rsnapshot']['server']['ssh_key']}"
      end if node['rsnapshot']['client']['server_search']

      ssh_keys
    end
  end
end
