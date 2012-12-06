#
# Cookbook Name:: cloudkick
# Recipe:: default
#
# Copyright 2010-2011, Opscode, Inc.
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

case node['platform_family']
when "debian"

  if node['platform'] == 'ubuntu' && node['platform_version'].to_f >= 11.10
    codename = 'lucid'
  else
    codename = node['lsb']['codename']
  end

  apt_repository "cloudkick" do
    uri "http://packages.cloudkick.com/ubuntu"
    distribution codename
    components ["main"]
    key "http://packages.cloudkick.com/cloudkick.packages.key"
    action :add
  end

  if node['platform'] == 'ubuntu' && node['platform_version'].to_f >= 11.10
    package "libssl0.9.8"
  end

when "rhel", "fedora"

  yum_repository "cloudkick" do
    url "http://packages.cloudkick.com/redhat/$basearch"
    action :add
  end

  if (node['platform'] == 'centos' && node['platform_version'].to_f >= 6.0)
    rpm_package "" do
      source "http://packages.cloudkick.com/releases/cloudkick-config/binaries/cloudkick-config-centos6-1.2.1-0.x86_64.rpm"
    end
  end

end

remote_directory node['cloudkick']['local_plugins_path'] do
  source "plugins"
  mode "0755"
  files_mode "0755"
  files_backup 0
  recursive true
end

package "cloudkick-agent" do
  action :install
end

# The configure recipe is broken out so that reconfiguration
# is lightening fast (no package installation checks, etc).
include_recipe "cloudkick::configure"

# oauth gem for http://tickets.opscode.com/browse/COOK-797
chef_gem "oauth"
chef_gem "cloudkick"

# This seems to require chef-server search capability,
# but it times out harmlessly when using chef-solo.
ruby_block "cloudkick data load" do
  block do
    require 'oauth'
    require 'cloudkick'
    begin
      node.set['cloudkick']['data'] = Chef::CloudkickData.get(node)
    rescue Exception => e
      Chef::Log.warn("Unable to retrieve Cloudkick data for #{node.name}\n#{e}")
    end
  end
  action :create
end
