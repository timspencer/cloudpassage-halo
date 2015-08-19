# Cookbook Name:: cloudpassage
# Recipe:: delete
# Delete everything and make sure it's killed
# Copyright 2015, CloudPassage

# FOR TESTING PURPOSES ONLY.

###
# nuke cphalo packages
###
package 'cphalo' do
  if node[:platform_family] == 'debian'
    action :purge
  else
    action :remove
  end
end

windows_package 'CloudPassage Halo' do
  action :remove
  only_if node[:platform_family] == 'windows'
end

###
# kill everything, just in case the package stuff doesn't
###
execute 'kill cphalo' do
  not_if { node[:platform_family] == 'windows' }
  command "ps gaxuwww | egrep -v 'grep|awk' | awk '/opt.cloudpassage.bin.cphalo/ {print $2}' | xargs kill -9"
end

###
# remove all files, just in case the package doesn't
###
case node[:platform_family]
when 'windows'
  halopath = 'c:\Program Files\CloudPassage'
else
  halopath = '/opt/cloudpassage'
end
directory halopath
  action :delete
  recursive true
end

