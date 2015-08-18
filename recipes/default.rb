# Cookbook Name:: cloudpassage
# Recipe:: default
# Initial Start of Cookbook
# Copyright 2014, CloudPassage

# First we build the proxy string

###
# Defining the tag
###
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
      command "dpkg -i #{dpath}
      action :nothing
      notifies :create, 'template[cphalo.properties]', :immediately
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
      notifies :create, 'template[cphalo.properties]', :immediately
    end
  when 'windows'
    windows_package 'CloudPassage Halo' do
      source node[:cloudpassage][:win_location]
      installer_type :custom
      options "/S /daemon-key=#{node[:cloudpassage]['daemon_key']}"
      action :install
      notifies :create, 'template[cphalo.properties]', :immediately
  end
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
  owner root
  action :nothing
end

XXX kill everything if there are more than one?


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
end

XXX delete properties file here?


