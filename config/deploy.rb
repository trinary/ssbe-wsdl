set :application, "rails-ws"
set :repository,  "git://github.com/trinary/ssbe-wsdl.git"

set :scm, :git
# Or: `accurev`, `bzr`, `cvs`, `darcs`, `git`, `mercurial`, `perforce`, `subversion` or `none`
set :deploy_to, "/opt/#{application}"
set :user, "root"
set :use_sudo, false

#role :web, "your web-server here"                          # Your HTTP server, Apache/etc
#role :app, "qa-sssdp02-proc01.boulder.api.local"
#role :db,  "your primary db-server here", :primary => true # This is where Rails migrations will run
#role :db,  "your slave db-server here"
#
#server "qa-ssdp02-proc01.boulder.api.local", :app
server "ssint2-proc01.fortrust.api.local", :app
server "ssint2-proc02.fortrust.api.local", :app

# If you are using Passenger mod_rails uncomment this:
# if you're still using the script/reapear helper you will need
# these http://github.com/rails/irs_process_scripts

namespace :deploy do
   task :start do
   end
   task :stop do
   end
   task :restart, :roles => :app, :except => { :no_release => true } do
     run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
   end
 end
