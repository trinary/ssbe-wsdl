set :application, "rails-ws"
set :repository,  "ssh://git.dev.api.local/git/ssbe/rails-ws.git"
set :use_sudo, false
set :user, 'root'

# load 'ext/rails-database-migrations.rb'
# load 'ext/rails-shared-directories.rb'

# load 'ext/spinner.rb'              # Designed for use with script/spin
# load 'ext/passenger-mod-rails.rb'  # Restart task for use with mod_rails
# load 'ext/web-disable-enable.rb'   # Gives you web:disable and web:enable

# If you aren't deploying to /u/apps/#{application} on the target
# servers (which is the default), you can specify the actual location
# via the :deploy_to variable:
set :deploy_to, "/opt/#{application}"

# set :scm, "git"
# see a full list by running "gem contents capistrano | grep 'scm/'"

role :web, "172.18.0.15"
role :app, "172.18.0.15"

namespace :deploy do
  task :start, :roles => :app do
    run "touch #{current_release}/tmp/restart.txt"
  end

  task :stop, :roles => :app do
    # Do nothing.
  end

  desc "Restart Application"
  task :restart, :roles => :app do
    run "touch #{current_release}/tmp/restart.txt"
  end
end
