#
# Cookbook Name:: tomcat
# Recipe:: ark
# Author:: Bryan W. Berry (<bryan.berry@gmail.com>)
# Copyright 2010, Opscode, Inc.
# Copyright 2012, Bryan W. Berry
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

include_recipe "ark"

version = node['tomcat']['version'].to_s
tomcat_version = "tomcat#{node['tomcat']['version'].to_s}"

distro = value_for_platform_family(
  'fedora' => 'el',
  'rhel' => 'el',
  'default' => 'debian',
)

user node['tomcat']['user']

directory "/usr/local/tomcat" do
  owner node['tomcat']['user']
end

execute "remove_default_tomcat_apps" do
  command "rm -rf #{node["tomcat"]["home"]}/webapps/ROOT.war #{node["tomcat"]["home"]}/webapps/manager.war"
  action :nothing
end

ark tomcat_version do
  url node['tomcat'][version]['url']
  checksum node['tomcat'][version]['checksum']
  version node['tomcat']['version']
  path  "/usr/local/tomcat"
  home_dir node['tomcat']['home']
  owner node['tomcat']['user']
  notifies :run, "execute[remove_default_tomcat_apps]", :immediately
end

init_script = template tomcat_version do
  path "/etc/init.d/#{tomcat_version}"
  source "tomcat.init.#{distro}.erb"
  owner "root"
  group "root"
  mode "0774"
  variables( :name => tomcat_version)
end

service tomcat_version do
  supports :restart => true, :reload => true, :status => true
  action [:enable]
  notifies :start, "service[#{tomcat_version}]", :delayed
end

template "/etc/default/#{tomcat_version}" do
  source "default_tomcat.erb"
  owner "root"
  group "root"
  variables(:tomcat => node['tomcat'].to_hash)
  mode "0644"
  notifies :restart, "service[#{tomcat_version}]", :delayed
end

