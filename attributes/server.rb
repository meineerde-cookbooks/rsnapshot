default['rsnapshot']['server']['config_file'] = "/etc/rsnapshot.conf"

default['rsnapshot']['server']['snapshot_root'] = "/backup"
# The contents of the public key shipped to the clients
# This is overwritten on each invocation of the server recipe!
default['rsnapshot']['server']['ssh_key'] = nil

default['rsnapshot']['server']['intervals']['hourly'] = 2
default['rsnapshot']['server']['intervals']['daily'] = 7
default['rsnapshot']['server']['intervals']['weekly'] = 2
default['rsnapshot']['server']['intervals']['monthly'] = nil

default['rsnapshot']['server']['exclude'] = [
  'Recycled',
  'Trash',
  'lost+found',
  '.gvfs'
]

# additional clients which can not be inferred from the client role
default['rsnapshot']['server']['clients'] = {}
