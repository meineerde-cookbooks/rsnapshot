default['rsnapshot']['client']['user'] = 'rsnapshot'
default['rsnapshot']['client']['create_user'] = true
default['rsnapshot']['client']['manage_authorized_keys'] = true

default['rsnapshot']['client']['rsync_nice'] = nil
default['rsnapshot']['client']['rsync_ionice'] = nil

default['rsnapshot']['client']['backup_paths'] = []

default['rsnapshot']['client']['ssh_config'] = {}

default['rsnapshot']['client']['server_search'] = 'roles:rsnapshot_server'
# The attribute name containing the IP address on the node object
# retrieved via search. You can specify nested attributes by specifying them
# in the string separated by slashes.
default['rsnapshot']['client']['server_search_ip_attr'] = 'ipaddress'

# Additional servers which can not be inferred from the server search
# Example:
# {
#   "backup.example.com" => "ssh-rsa AAABBB01234..."
# }
default['rsnapshot']['client']['servers'] = {}
