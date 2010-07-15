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

file "/etc/apt/sources.list.d/soren-nova.list" do
  contents <<-EOH
deb http://ppa.launchpad.net/soren/nova/ubuntu lucid main
deb http://173.203.107.207/ubuntu ./
  EOH
  mode "0644"
end

bash "grab gpg keys" do
  code <<-EOH
gpg --keyserver hkp://keys.gnupg.net --recv-keys AB0188513FD35B23
gpg -a --export AB0188513FD35B23 | apt-key add -
  EOH
  subscribes :run, resources(:file => "/etc/apt/sources.list.d/soren-nova.list"), :immediately
  action :nothing
end

execute "apt-get update" do
  subscribes :run, resources(:file => "/etc/apt/sources.list.d/soren-nova.list"), :immediately
  action :nothing
end

%w{nova-compute nova-api nova-objectstore redis-server rabbitmq-server euca2ools unzip parted}.each do |pkg|
  package pkg
end

service "nginx" do
  action :restart
end

