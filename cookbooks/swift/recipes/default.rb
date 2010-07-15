#
# Cookbook Name:: cloudfiles
# Recipe:: default
#
# Copyright 2010, Opscode, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe 'apt'

%w{curl gcc bzr memcached python-configobj python-coverage python-dev python-nose python-setuptools python-simplejson python-xattr sqlite3 xfsprogs xfsprogs xfsdump acl attr}.each do |pkg_name|
  package pkg_name
end

%w{eventlet webob}.each do |python_pkg|
  easy_install_package python_pkg 
end

execute "build swiftfs" do
  command "dd if=/dev/zero of=/swiftfs bs=1024 count=1024000" 
  not_if { File.exists?("/swiftfs") }
end

execute "associate loopback" do
  command "losetup /dev/loop0 /swiftfs" 
  not_if { `losetup /dev/loop0` =~ /swiftfs/ }
end

execute "build filesystem" do
  command "mkfs.xfs -i size=1024 /dev/loop0"
  not_if 'xfs_admin -u /dev/loop0'
end

directory "/mnt/sdb1" do 
  mode "0755"
  owner "root"
  group "root"
end

execute "update fstab" do
  command "echo '/dev/loop0 /mnt/sdb1 xfs noauto,noatime,nodiratime,nobarrier,logbufs=8 0 0' >> /etc/fstab"
  not_if "grep '/dev/loop0' /etc/fstab"
end

execute "mount /mnt/sdb1" do
  not_if "df | grep /dev/loop0"
end

%w{1 2 3 4 test}.each do |swift_dir|
  directory "/mnt/sdb1/#{swift_dir}" do
    owner node[:cloudfiles][:user] 
    group node[:cloudfiles][:group] 
    mode "0755"
  end

  link "/tmp/#{swift_dir}" do
    to "/mnt/sdb1/#{swift_dir}"
  end

  link "/srv/#{swift_dir}" do
    to "/mnt/sdb1/#{swift_dir}"
  end
end

directory "/etc/swift" do
  owner node[:cloudfiles][:user]
  group node[:cloudfiles][:group]
  mode "0755"
end

%w{/etc/swift/object-server /etc/swift/container-server /etc/swift/account-server /var/run/swift}.each do |new_dir|
  directory new_dir do
    owner node[:cloudfiles][:user]
    group node[:cloudfiles][:group]
    recursive true
    mode "0755"
  end
end

template "/etc/rsyncd.conf" do
  source "rsyncd.conf.erb"
end

cookbook_file "/etc/default/rsync" do
  source "default-rsync"
end

service "rsync" do
  action :start
end

directory "#{node[:cloudfiles][:homedir]}/bin" do
  owner node[:cloudfiles][:user]
  group node[:cloudfiles][:group]
  mode "0755"
end

directory "#{node[:cloudfiles][:homedir]}/.bazaar" do
  owner node[:cloudfiles][:user]
  group node[:cloudfiles][:group]
  mode "0755"
end

file "#{node[:cloudfiles][:homedir]}/.bazaar/.bazaar.conf" do
  content <<-EOH
[DEFAULT]
  email = #{node[:cloudfiles][:bzr_email]}
  EOH
  owner node[:cloudfiles][:user]
  group node[:cloudfiles][:group]
  mode "0644"
end

execute "bzr launchpad-login #{node[:cloudfiles][:launchpad_login]}" do
  user node[:cloudfiles][:user]
  cwd node[:cloudfiles][:homedir]
  not_if "bzr launchpad-login"
end

execute "bzr branch #{node[:cloudfiles][:bzr_branch]} swift" do
  user node[:cloudfiles][:user]
  cwd node[:cloudfiles][:homedir]
  not_if { File.directory?("#{node[:cloudfiles][:homedir]}/swift") }
end

ruby_block "symlink swift" do
  block do
    Dir["#{node[:cloudfiles][:homedir]}/swift/bin/*"].each do |file|
      r = Chef::Resource::Link.new("/usr/bin/#{File.basename(file, '.py')}", self.run_context)
      r.to file
      r.run_action :create
    end
  end
end

ENV["PYTHONPATH"] = "~/swift"
ENV["PATH_TO_TEST_XFS"] = "/mnt/sdb1/test"
ENV["SWIFT_TEST_CONFIG_FILE"] = '/etc/swift/func_test.conf'
ENV["PATH"] += ":~/bin"

[ 
  'export PYTHONPATH=~/swift',
  'export PATH_TO_TEST_XFS=/mnt/sdb1/test',
  'export SWIFT_TEST_CONFIG_FILE=/etc/swift/func_test.conf',
  'export PATH=${PATH}:~/bin' 
].each do |bash_bit|
  execute "echo '#{bash_bit}' >> ~/.bashrc" do
    not_if "grep '#{bash_bit}' ~/.bashrc"
  end
end

template "/etc/swift/auth-server.conf" do
  source "auth-server.conf.erb"
  mode "0644"
  owner node[:cloudfiles][:user]
  group node[:cloudfiles][:group]
end

template "/etc/swift/proxy-server.conf" do
  source "proxy-server.conf.erb"
  mode "0644"
  owner node[:cloudfiles][:user]
  group node[:cloudfiles][:group]
end

%w{1 2 3 4}.each do |server_num|
  %w{account container object}.each do |server_type|
    template "/etc/swift/#{server_type}-server/#{server_num}.conf" do
      variables({ :server_num => server_num })
      source "#{server_type}-server-conf.erb"
      mode "0644"
      owner node[:cloudfiles][:user]
      group node[:cloudfiles][:group]
    end
  end
end

%w{resetswift remakerings startmain startrest}.each do |bin_file|
  template "#{node[:cloudfiles][:homedir]}/bin/#{bin_file}" do
    source "#{bin_file}.erb"
    owner node[:cloudfiles][:user]
    group node[:cloudfiles][:group]
    mode "0755"
  end
end

template "/etc/swift/func_test.conf" do
  source "func_test.conf.erb"
  owner node[:cloudfiles][:user]
  group node[:cloudfiles][:group]
  mode "0644"
end

