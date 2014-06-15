require 'recap/recipes/ruby'

set :application, 'webhooks'
set :repository, 'git@github.com:freerange/webhooks.git'

server 'alpaca.gofreerange.com', :app

namespace :deploy do
  task :restart do
    as_app "mkdir -p tmp && touch tmp/restart.txt"
  end
end
