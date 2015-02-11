module Rsnapshot
  module RecipeHelpers
    def rsnapshot_server_keys(options=%w[no-port-forwarding no-X11-forwarding no-agent-forwarding no-pty])
      ssh_keys = []
      search(:node, "#{node['rsnapshot']['server_search']} AND rsnapshot_server_ssh_key:* NOT name:#{node.name}") do |server|
        prefix  = ["from=\"#{server['ipaddress']}\"", "command=/usr/local/bin/rsnapshot-rsync"]
        prefix += options.map{|opt| opt.to_s.strip }
        ssh_keys << "#{prefix.join(',')} #{server['rsnapshot']['server']['ssh_key']}"
      end
      ssh_keys
    end
  end
end
