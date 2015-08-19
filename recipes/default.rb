# Cookbook Name:: cloudpassage
# Recipe:: default
# Initial Start of Cookbook
# Copyright 2014, CloudPassage

# FOR TESTING PURPOSES ONLY.  NOT FOR USE WITH HALO >= 3.5.0 OR YOU WON'T HAVE FUN

###
# Defining the tag
###
if node.default.cloudpassage.tag == nil
  case node.platform
  when "oracle"
    if node.platform_version =~ /6/
      node.default.cloudpassage.tag = "oel6"
    else
      node.default.cloudpassage.tag = "oel5"
    end
  when "ubuntu"
    node.default.cloudpassage.tag = "ubuntu14"
  when "windows"
    if node.platform_version.to_f >= 6.2
      node.default.cloudpassage.tag = "win2012"
    else
      node.default.cloudpassage.tag = "win2008r2"
    end
  end
end

###
# install cphalo and related packages
###
if (node[:cloudpassage]['rpm_url'] == nil) && (node[:cloudpassage]['deb_url'] == nil) && (node[:cloudpassage]['win_location'] == nil)
  package 'cphalo'
else
  case node[:platform_family]
  when 'debian'
    package 'lsof'
    dpath = "#{Chef::Config[:file_cache_path]}/cphalo_3.2.9_amd64.deb"
    remote_file dpath do
      source node[:cloudpassage]['deb_url']
      action :create_if_missing
      notifies :run, 'execute[install_halo_deb]', :immediately
    end
    execute 'install_halo_deb' do
      command "dpkg -i #{dpath}"
      action :nothing
      notifies :create, 'ruby_block[edit_cphalod_init]', :immediately
    end

  when 'rhel'
    package 'lsof'
    rpath = "#{Chef::Config[:file_cache_path]}/cphalo-3.2.9-1.x86_64.rpm"
    remote_file rpath do
      source node[:cloudpassage]['rpm_url']
      action :create_if_missing
      notifies :run, 'execute[install_halo_rpm]', :immediately
    end
    execute 'install_halo_rpm' do
      command "rpm -ivh #{rpath}"
      action :nothing
      notifies :create, 'ruby_block[edit_cphalod_init]', :immediately
    end

  when 'windows'
    windows_package 'CloudPassage Halo' do
      source node[:cloudpassage][:win_location]
      installer_type :custom
      options "/S /daemon-key=#{node[:cloudpassage]['daemon_key']}"
      action :install
      notifies :create, 'ruby_block[edit_cphalod_init]', :immediately
    end
  end
end

# This is so ugly, but we need to do this because older daemon init files just rm
# the properties file.  :-(  This should not be needed once we move to 3.5.0+.
ruby_block "edit_cphalod_init" do
  block do
    fe = Chef::Util::FileEdit.new("/etc/init.d/cphalod")
    fe.search_file_replace_line(/^ *rm -f .CP.data.cphalo.properties/, "  #rm -f $CP/data/cphalo.properties")
    fe.write_file
  end
  # only_if XXX something to detect < 3.5.0 maybe someday
  not_if "/bin/egrep '^  #rm -f .CP/data/cphalo' /etc/init.d/cphalod >/dev/null"
  action :nothing
  notifies :create, 'template[cphalo.properties]', :immediately
end

###
# if the package is newly installed, this will be laid down to configure it
###
case node[:platform_family]
when 'windows'
  propertiespath = 'c:\Program Files\CloudPassage\data\cphalo.properties'
else
  propertiespath = '/opt/cloudpassage/data/cphalo.properties'
end
template 'cphalo.properties' do
  path propertiespath
  source 'cphalo.properties.erb'
  mode 0600
  owner 'root'
  action :nothing
  notifies :run, 'execute[initialize_halo]', :immediately
end

###
# If this is an initial install, start it up with the daemon key and then shut it down
# Man, this is so much easier if you do this in the bootstrap.
###
execute 'initialize_halo' do
  command "/etc/init.d/cphalod start --daemon-key=#{node[:cloudpassage]['daemon_key']} ; sleep 5 ; /etc/init.d/cphalod stop"
  action :nothing
end

# kill everything if there are more than one daemon running.
# We believe this will fix a strange problem with corruption of it's
# data files if you have more than one going...  We hope.
execute 'kill everything if there are too many' do
  not_if { node[:platform_family] == 'windows' }
  only_if "PROCS=`ps gaxuwww | grep -v grep | grep /opt/cloudpassage/bin/cphalo | wc -l` ; if [ $PROCS -gt 2 ] ; then true ; else false ; fi"
  command "ps gaxuwww | egrep -v 'grep|awk' | awk '/opt.cloudpassage.bin.cphalo/ {print $2}' | xargs kill -9"
  notifies :restart, 'service[cphalod]'
end

###
# Make sure it's started up and configured to start upon reboot!
###
case node[:platform_family]
when 'windows'
  p_serv_name = 'cphalo'
else
  p_serv_name = 'cphalod'
end
service p_serv_name do
  action [ "enable", "start"]
  supports :status => true, :start => true, :stop => true, :restart => true
end

