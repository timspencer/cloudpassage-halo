# Daemon key:  If this isn't set, the daemon will not be able to start up.
#default[:cloudpassage]['daemon_key'] = 'XXX'

# URL for the packages.  If these are set, then use these instead of just
# normal apt-get/yum package stuff.
default[:cloudpassage]['deb_url'] = nil
default[:cloudpassage]['rpm_url'] = nil
default[:cloudpassage]['win_location'] = nil

# grid: specifies the grid you want to use.  Replace/override nil with
# grid URL if you have your own VPG.
default[:cloudpassage][:grid] = nil

# proxy stuff:  Replace/override nil with proxy info if you use proxies.
default[:cloudpassage][:proxy_url] = nil
default[:cloudpassage][:proxy_user] = nil
default[:cloudpassage][:proxy_pass] = nil

# tag:  This specifies server group to use.  Replace/override nil with
# tag if you want to set a tag.
default[:cloudpassage][:tag] = nil

# dns:  This lets you set --dns=true/false if you want to.  Replace/override
# with your value if you need to use this.
default[:cloudpassage][:dns] = nil

