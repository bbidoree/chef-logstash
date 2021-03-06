# Encoding: utf-8
#
# Author:: John E. Vincent
# Author:: Bryan W. Berry (<bryan.berry@gmail.com>)
# Copyright 2012, John E. Vincent
# Copyright 2012, Bryan W. Berry
# License: Apache 2.0
# Cookbook Name:: logstash
# Recipe:: server
#
#

# install logstash 'server'

name = 'server'

Chef::Application.fatal!("attribute hash node['logstash']['instance']['#{name}'] must exist.") if node['logstash']['instance'][name].nil?

# these should all default correctly.  listing out for example.
logstash_instance name do
  action            :create
end

# services are hard! Let's go LWRP'ing.   FIREBALL! FIREBALL! FIREBALL!
logstash_service name do
  action      [:enable]
end

my_templates = node['logstash']['instance'][name]['config_templates']

if my_templates.nil?
  my_templates = {
    'input_syslog' => 'config/input_syslog.conf.erb',
    'output_stdout' => 'config/output_stdout.conf.erb',
    'output_elasticsearch' => 'config/output_elasticsearch.conf.erb'
  }
end

logstash_config name do
  templates my_templates
  action [:create]
  variables(
    elasticsearch_protocol: "http"
  )
  notifies :restart, "logstash_service[#{name}]"
end
# ^ see `.kitchen.yml` for example attributes to configure templates.

logstash_plugins 'contrib' do
  instance name
  action [:create]
end

logstash_pattern name do
  action [:create]
end

#logstash_curator 'server' do
#  action [:create]
#end

base_dir = node['logstash']['instance'][name]['basedir']
if base_dir.nil?
  base_dir = node['logstash']['instance']['default']['basedir']
end

template 'milkLogAnalysisFilter.rb' do
  path   "#{base_dir}/#{name}/lib/logstash/filters/milkLogAnalysisFilter.rb"
  source '/filters/milkLogAnalysisFilter.rb.erb'
  owner  node['logstash']['instance'][name]['user']
  group  node['logstash']['instance'][name]['group']
  mode '0664'
end

template 'milkLogAnalyser.rb' do
  path   "#{base_dir}/#{name}/lib/milkLogAnalyser.rb"
  source '/lib/milkLogAnalyser.rb.erb'
  owner  node['logstash']['instance'][name]['user']
  group  node['logstash']['instance'][name]['group']
  mode '0664'
end

template 'milkLogAnalyserRunner.rb' do
  path   "#{base_dir}/#{name}/lib/milkLogAnalyserRunner.rb"
  source '/lib/milkLogAnalyserRunner.rb.erb'
  owner  node['logstash']['instance'][name]['user']
  group  node['logstash']['instance'][name]['group']
  mode '0664'
end

bash "gem" do
  user "root"
  code <<-EOH
    gem install elasticsearch
    gem install hashie
  EOH
end

