require 'recap/recipes/ruby'

set :application, 'webhooks'
set :repository, 'git@github.com:freerange/webhooks.git'
set :branch, 'migrating-to-another-server'

server 'badger.gofreerange.com', :app

namespace :deploy do
  task :restart do
    as_app "mkdir -p tmp && touch tmp/restart.txt"
  end
end

namespace :apache do
  desc "Copy the apache config file from this app to /etc/apache2/sites-available"
  task :update_config do
    apache_config = File.join(deploy_to, 'config', 'apache', 'webhooks.gofreerange.com.conf')
    sudo "cp #{apache_config} /etc/apache2/sites-available/"
  end

  desc "Reload the Apache webserver, particularly useful after updating the Apache config"
  task :reload do
    sudo "service apache2 reload"
  end
end

after "apache:update_config", "apache:reload"
