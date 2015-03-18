require 'shellwords'


default['rsnapshot']['server']['commands']['rsnapshot'] = '/usr/bin/rsnapshot'
default['rsnapshot']['server']['commands']['sync'] = '/usr/bin/rsnapshot sync'

default['rsnapshot']['server']['config_file'] = '/etc/rsnapshot.conf'

default['rsnapshot']['server']['config']['snapshot_root'] = '/backup'
default['rsnapshot']['server']['config']['no_create_root'] = '1'

default['rsnapshot']['server']['config']['cmd_rsync'] = '/usr/bin/rsync'
default['rsnapshot']['server']['config']['rsync_short_args'] = '-az'
default['rsnapshot']['server']['config']['rsync_long_args'] = '--delete --numeric-ids --relative --delete-excluded --stats'
default['rsnapshot']['server']['config']['link_dest'] = '1'

default['rsnapshot']['server']['config']['cmd_cp'] = '/bin/cp'
default['rsnapshot']['server']['config']['cmd_du'] = '/usr/bin/du'
default['rsnapshot']['server']['config']['cmd_logger'] = '/usr/bin/logger'
default['rsnapshot']['server']['config']['cmd_rm'] = '/bin/rm'
# Some versions of rsnapshot (e.g. 1.3.1-4) are broken and incorrectly pass
# ssh arguments due to broken quoting. Because of that, we use an external
# ssh config file by default.
# In these broken versions, you can't set any ssh_args directly. Use
# node['rsnapshot']['server']['ssh_config'] (see below) and the default
# wrapper script instead.
default['rsnapshot']['server']['config']['cmd_ssh'] = '/usr/local/sbin/rsnapshot-ssh'
default['rsnapshot']['server']['config']['ssh_args'] = nil

# Verbose level, 1 through 5.
# 1     Quiet           Print fatal errors only
# 2     Default         Print errors and warnings only
# 3     Verbose         Show equivalent shell commands being executed
# 4     Extra Verbose   Show extra verbose information
# 5     Debug mode      Everything
default['rsnapshot']['server']['config']['verbose'] = 2

# Same as verbose above, but controls the amount of data sent to the logfile
default['rsnapshot']['server']['config']['loglevel'] = 3
default['rsnapshot']['server']['config']['logfile'] = '/var/log/rsnapshot.log'

default['rsnapshot']['server']['config']['lockfile'] = '/var/run/rsnapshot.pid'
default['rsnapshot']['server']['config']['stop_on_stale_lockfile'] = '0'

# don't span filesystem partitions within a backup point.
default['rsnapshot']['server']['config']['one_fs'] = '1'

# sync first and perform lazy deletes
# This makes the sync step more predictable time-wise but requires more
# storage space. Youy should sisable this only if you can cope with the
# issues and ensure your jobs can run in the allotted time.
default['rsnapshot']['server']['config']['sync_first'] = '1'
default['rsnapshot']['server']['config']['use_lazy_deletes'] = '1'

# Globally exclude some directories
# These NEED to have a trailing slash!
default['rsnapshot']['server']['config']['exclude'] = [
  'Recycled/',
  'Trash/',
  'lost+found/',
  '.gvfs/'
]

# The contents of the public key shipped to the clients
# This is overwritten on each invocation of the server recipe!
default['rsnapshot']['server']['ssh_key'] = nil

# The default options in the generated ssh client config file
default['rsnapshot']['server']['ssh_config']['batch_mode'] = 'yes'
default['rsnapshot']['server']['ssh_config']['identities_only'] = 'yes'
default['rsnapshot']['server']['ssh_config']['identity_file'] = "#{Shellwords.escape node['etc']['passwd']['root']['dir']}/.ssh/id_rsa"
default['rsnapshot']['server']['ssh_config']['port'] = '22'

# Calculate the hours when to run the hourlay interval
# The count parameter should be a divisor of 24, e.g. 2, 3, 4, 6, ...
cron_hourly = ->(count, starting_hour=4) do
  interval = 24 / count.to_i
  count.to_i.times.map do |i|
    (interval * i + starting_hour) % 24
  end
end

# Define the retain intervals in their exact order.
default['rsnapshot']['server']['retain'] = ['hourly', 'daily', 'weekly', 'monthly']

default['rsnapshot']['server']['intervals']['hourly']['keep'] = 2
default['rsnapshot']['server']['intervals']['hourly']['cron']['hour'] = cron_hourly.(node['rsnapshot']['server']['intervals']['hourly']['keep']).join(',')
default['rsnapshot']['server']['intervals']['hourly']['cron']['minute'] = 0
default['rsnapshot']['server']['intervals']['hourly']['cron']['day'] = '*'
default['rsnapshot']['server']['intervals']['hourly']['cron']['month'] = '*'
default['rsnapshot']['server']['intervals']['hourly']['cron']['weekday'] = '*'
default['rsnapshot']['server']['intervals']['hourly']['cron']['mailto'] = nil

default['rsnapshot']['server']['intervals']['daily']['keep'] = 7
default['rsnapshot']['server']['intervals']['daily']['cron']['hour'] = 3
default['rsnapshot']['server']['intervals']['daily']['cron']['minute'] = 30
default['rsnapshot']['server']['intervals']['daily']['cron']['day'] = '*'
default['rsnapshot']['server']['intervals']['daily']['cron']['month'] = '*'
default['rsnapshot']['server']['intervals']['daily']['cron']['weekday'] = '*'
default['rsnapshot']['server']['intervals']['daily']['cron']['mailto'] = nil

default['rsnapshot']['server']['intervals']['weekly']['keep'] = 2
default['rsnapshot']['server']['intervals']['weekly']['cron']['hour'] = 3
default['rsnapshot']['server']['intervals']['weekly']['cron']['minute'] = 0
default['rsnapshot']['server']['intervals']['weekly']['cron']['day'] = '*'
default['rsnapshot']['server']['intervals']['weekly']['cron']['month'] = '*'
default['rsnapshot']['server']['intervals']['weekly']['cron']['weekday'] = 1 # Monday
default['rsnapshot']['server']['intervals']['weekly']['cron']['mailto'] = nil

default['rsnapshot']['server']['intervals']['monthly']['keep'] = nil
default['rsnapshot']['server']['intervals']['monthly']['cron']['hour'] = 2
default['rsnapshot']['server']['intervals']['monthly']['cron']['minute'] = 30
default['rsnapshot']['server']['intervals']['monthly']['cron']['day'] = 1
default['rsnapshot']['server']['intervals']['monthly']['cron']['month'] = '*'
default['rsnapshot']['server']['intervals']['monthly']['cron']['weekday'] = '*'
default['rsnapshot']['server']['intervals']['monthly']['cron']['mailto'] = nil

default['rsnapshot']['server']['client_search'] = 'roles:rsnapshot_client'
# The attribute name containing the IP address on the node object
# retrieved via search. You can specify nested attributes by specifying them
# in the string separated by slashes.
default['rsnapshot']['server']['client_search_ip'] = 'ipaddress'

# Additional clients which can not be inferred from the client search
# Example:
# {
#   "web1.example.com" => {
#     "backup_paths" => ["/", "/data"],
#     "user" => "backup",
#     "ssh_config" => {
#       "port" => 2222
#     }
#   }
# }
default['rsnapshot']['server']['clients'] = {}
