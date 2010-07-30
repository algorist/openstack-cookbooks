#
# Cookbook Name:: redis
# Recipe:: default
#
# Copyright 2010, Opscode
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

include_recipe "build-essential"
include_recipe "runit"

remote_file "/tmp/redis-#{node[:redis][:version]}.tar.gz" do
  source "http://redis.googlecode.com/files/redis-#{node[:redis][:version]}.tar.gz"
  not_if do
    File.exists?("/usr/local/bin/redis-server")
  end
end

redis_binaries = %w{ redis-benchmark redis-check-aof redis-check-dump redis-cli redis-server }

bash "install redis" do
  cwd "/tmp"
  code <<-EOH
    cd /tmp
    tar zxvf /tmp/redis-#{node[:redis][:version]}.tar.gz
    cd /tmp/redis-#{node[:redis][:version]}
    make
    cp #{redis_binaries.join(" ")} /usr/local/bin
  EOH
  action :nothing
  subscribes :run, resources(:remote_file => "/tmp/redis-#{node[:redis][:version]}.tar.gz"), :immediately
end

redis_binaries.each do |bin|
  file "/usr/local/bin/#{bin}" do
    mode "0755"
  end
end

runit_service "redis"
