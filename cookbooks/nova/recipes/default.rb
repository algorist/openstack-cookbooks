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

include_recipe "apt"

file "/etc/apt/sources.list.d/nova.list" do
  content <<-EOH
deb http://nova.openstack.org/pkgs ./
  EOH
  mode "0644"
end

execute "apt-get update" do
  subscribes :run, resources(:file => "/etc/apt/sources.list.d/nova.list"), :immediately
  action :nothing
end

%w{euca2ools unzip parted nova-compute nova-api nova-objectstore}.each do |pkg|
  package pkg do
    options "--force-yes"
  end
end

service "nginx" do
  action :restart
end

execute "nova-manage user admin #{node[:nova][:user]}" do
  not_if "nova-manage user list | grep #{node[:nova][:user]}"
end

execute "nova-manage project create #{node[:nova][:project]} #{node[:nova][:user]}" do
  not_if "nova-manage project list | grep #{node[:nova][:project]}"
end

