#
# Cookbook Name:: nova
# Recipe:: devel
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

include_recipe "openldap::nova"
include_recipe "redis"
include_recipe "rabbitmq"

easy_install_package "virtualenv"
easy_install_package "pip"

package "build-dep"
package "python-m2crypto"
package "bzr"

execute "bzr init -repo nova" do
  cwd "/srv"
  not_if { File.directory?("/srv/nova") }
end

execute "bzr branch #{node[:nova][:bzr_branch]} running" do
  cwd "/srv/nova"
  not_if { File.directory?("#{node[:nova][:bzr_branch]}/running") }
end

execute "python tools/install_venv.py" do
  cwd "/srv/nova/
end
