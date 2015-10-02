include_recipe 'chef-solo-search'
include_recipe 'apt'

package [
	'curl',
  'tree',
  'htop',
  'nodejs',
  'libsqlite3-dev'
] do
  action :install
end

# ruby and rails
node.set[:languages][:ruby][:default_version] = '2.2.3'
include_recipe 'ruby'

execute 'install_rails' do
  command "gem install rails -v 4.2.2"
  not_if 'gem list | grep "rails" | grep "4.2.2"'
end

# elasticsearch
node.set['java']['jdk_version'] = '7'
include_recipe 'java' # scala has java in it
include_recipe 'elasticsearch'
elasticsearch_install 'elasticsearch'
elasticsearch_configure 'elasticsearch'
elasticsearch_service 'elasticsearch'
elasticsearch_plugin 'mobz/elasticsearch-head'

service "elasticsearch" do
  action :start
end

# create banjo index if not there
mapping_path = '/opt/banjo/sandbox/app/exercise_mapping.json'

execute 'create_es_mapping' do
  command "curl -XPUT --data '@#{mapping_path}' localhost:9200/banjo/_mapping/tweets"
  action :nothing
end

execute 'create_es_index' do
  command "
    curl -XPOST localhost:9200/banjo -d '{
      \"settings\" : {
          \"number_of_shards\" : 1,
          \"number_of_replicas\" : 0
      }
    }'
  "
  not_if "curl -XHEAD -i localhost:9200/banjo | grep 200"
  notifies :run, 'execute[create_es_mapping]', :immediately
end

# use the latest mapping to the index

cookbook_file mapping_path do
  source 'exercise_mapping.json'
  mode '0755'
  action :create
end

# fireweall
include_recipe 'firewall'
firewall 'ufw' do
  action :enable
end

firewall_rule 'ssh' do
  port     22
  action   :allow
end

firewall_rule 'rails_dev' do
  port     3000
  protocol :tcp
  position 1
  action   :allow
end

firewall_rule 'elasticsearch' do
  port     9200
  protocol :tcp
  position 1
  action   :allow
end
