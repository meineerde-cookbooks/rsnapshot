maintainer       "Holger Just"
maintainer_email "hello@holgerjust.de"
license          "MIT"
description      "rsnapshot"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.0.1"

%w{ ubuntu debian}.each do |os|
  supports os
end

depends "cron"
depends "sudo"
