# Deploying Sinatra Microsites With Git

[Sinatra](http://www.sinatrarb.com/) is a Ruby microframework that makes
building small websites very fast and easy.  With a few more basic tools, you
can have a site up and running in less than a day with no maintenance and easy
git-based deployment with zero downtime.  In this post I'm going to cover how to
set up your stack and get your server serving in no time at all.

For brevity, I'm going to assume you're using Ubuntu, Mint, or another
Debian-based distro for your development machine and Ubuntu 14.04 on the server,
instructions for other distros will vary slightly but should be similar.  I will
also assume you are familiar with Linux basics (`mkdir`, `cd`, `nano`, `touch`,
`ssh`, `sudo`), as well as Git, but not necessarily with Ruby or any of the
other tools we'll be using.


## Local Configuration
On your development machine you'll need to first install `RVM`, the Ruby Version
Manager, which will handle setting up your basic Ruby environment.  If you need
a non-standard RVM installation you can check
[their documentation](https://rvm.io/rvm/install), but for our purposes we're
going to use the standard

```bash
\curl -sSL https://get.rvm.io | bash -s stable --ruby
```

This will install the stable branch of RVM and the latest stable version of Ruby.
You then need to run `source ~/.rvm/scripts/rvm` to make RVM available in your
terminal, and may want to put that in your `~/.bashrc`.


### .rvmrc
In your project directory, the first config file you need to create is a
`.rvmrc` for RVM to use.  You need two pieces of information for it: the Ruby
version you just installed and a name for your gemset (you can pick any name).
The gemset is the project-specific set of Ruby gems you'll be using.  If you
didn't make a note of the version of Ruby installed, you can find it with
`rvm list`.
In your `.rvmrc` you need to put a single line:

```bash
rvm use VERSION@GEMSET --install --create
```

replacing the version with your version number and the gemset with your chosen
gemset name, e.g.

```bash
rvm use 2.2.2@my_project --install --create
```

The install flag tells RVM to install that version of Ruby if it doesn't exist,
and the create flag tells RVM to create that gemset if it doesn't exist.  Once
your `.rvmrc` is ready, `cd` out of and back into your project directory.  RVM
will ask if you trust the `.rvmrc` file it finds, tell it 'yes' and it will load
your Ruby environment for you.


### Bundler
Next you need to `gem install bundler`.  Bundler is a gem which will handle all
your other gem dependencies for you in a pretty convenient way.  You then need
to create a `Gemfile` for Bundler to use.

Into your `Gemfile` you need to put the following:

```ruby
source 'https://rubygems.org'
#ruby=ruby-VERSION
#ruby-gemset=GEMSET

gem "haml"
gem "markdown"
gem "rerun"
gem "sinatra"
gem "unicorn"
```

again replacing the VERSION with your Ruby version number and the GEMSET with
your chosen gemset name.  The source defines where Bundler will look for any
gems not already installed on your system, and each gem line defines a gem to be
installed and used.  If you need any additional gems you can add them to the
list in the same way, I would recommend `sinatra-partial` (allows you to use
rails-style partial views) and `compass` (a SASS compiler and utility library
for cross-browser polyfills on experimental CSS features and the like).  If you
aren't going to use HAML and Markdown for your views and layout, you can replace
those gems with the appropriate ones for your project.

Once your `Gemfile` is ready, executing `bundle install` will get all your gems
ready for use.


### Application File and Rackup
Next you need to create your project's application file, e.g. `my_project.rb`,
which will contain your Sinatra application logic.

The first thing it needs to contain is

```ruby
require 'rubygems'
require 'bundler/setup'
Bundler.require(:default)
```

to ensure that your gemset is loaded by your application.  After that you can
include your basic application class

```ruby
class My_Project < Sinatra::Base

  get '/' do
    markdown :index
  end
end
```

Once your application file is ready, you need to create a `config.ru` file to
allow your application to run:

```ruby
# config.ru (run with rackup)
require './my_project'
run My_Project
````

where `./my_project` is the relative path to your application `.rb` file and
`My_Project` is the name of your application class.

Now is also a good time to create the four project subdirectories you'll be
using: `public`, `views`, `pids`, and `logs`.  For now, the only thing you need
to add to these is making a `views/index.md` file with "Hello World" for
testing.  You can then make sure your application is working by executing
`rackup` from your project directory and pointing your browser to
`localhost:9292`.

In the future, `views` will contain all your view and layout files, `public`
will contain all your public files (css, js, images, etc), and `logs` and `pids`
will be used by our full server stack.


## Unicorn and Nginx
We have two more config files to prepare, one each for Unicorn and Nginx.
Unicorn is a fast webserver for Ruby applications, while Nginx will act as our
lightweight reverse proxy and to deliver static files without impacting
Unicorn.

Decide now where you want your project's directory to be on the server, e.g.
`/home/yourname/www/myproject` or `/var/www/example.com` or as you prefer.
This will be used in several places so it's important to be consistent.

Make a `unicorn.rb` in your local project directory with the following:

```ruby
project_home = "/chosen/path/to/project"
project_name = "my_project"
pid_file = "#{project_home}/pids/unicorn.pid"

working_directory "#{project_home}"

pid pid_file

stderr_path "#{project_home}/logs/unicorn.log"
stdout_path "#{project_home}/logs/unicorn.log"

listen "/tmp/unicorn.#{project_name}.sock"

worker_processes 4

timeout 30

# zero downtime deploy magic
before_fork do |server, worker|
  old_pid = pid_file + '.oldbin'
  if File.exists?(old_pid) && server.pid != old_pid
    begin
      sig = (worker.nr + 1) >= server.worker_processes ? :QUIT : :TTOU
      Process.kill(sig, File.read(old_pid).to_i)
    rescue Errno::ENOENT, Errno::ESRCH
    end
  end
end
```

replacing `/chosen/path/to/project` with the path you've picked for your project
**on the server**, not your local development machine, and `my_project` with the
name of your application.  These are used to define the basic settings for
Unicorn.  Of special note is the final code block, which enables Unicorn to
automatically serve the updated version of your site every time it changes
without having to restart any services.

Now, instead of using `rackup` to start your local test webserver, you can use
`unicorn`, which will then be available at `localhost:8080`.

Your Nginx config file is `nginx.conf`, and needs to contain the following:

```
upstream my_project {
    server unix:/tmp/unicorn.my_project.sock fail_timeout=0;
}

server {
    server_name example.com
    listen 80;

    root /chosen/path/to/project/public;

    try_files $uri @my_project;

    location @my_project {
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Host $http_host;
        proxy_redirect off;
        proxy_pass http://my_project;
    }
}

```

again replacing all instances of `my_project` with your application name and
`/chosen/path/to/project` with the path you've picked for your project
**on the server**.  The socket path in the `upstream` must match the socket path
your `unicorn.rb` is `listen`ing for.  You should change the `server_name` to
your domain name.  This configuration file is telling Nginx to try to match URIs
to files in your `public` directory and, failing that, switch to Unicorn to let
your Sinatra application handle it.


That's it for now on your local machine!  You should create a git repository
in your project directory if you haven't already and commit everything.  We'll
be setting up the server next.


## Server Configuration
I won't cover how to spin up a DigitalOcean Droplet or other VPS and provision
it with ssh keys and the like, if you need help there I would suggest
[this guide](https://www.digitalocean.com/community/tutorial_series/new-ubuntu-14-04-server-checklist).
We're going to assume you have a server ready to go that you can `ssh` into as a
non-root user and start getting ready to accept your application.


### RVM and Bundler
You need to install RVM and Bundler on the server just like you did on your
local machine

```bash
\curl -sSL https://get.rvm.io | bash -s stable --ruby
gem install bundler
```

then make the folder for your project at the location you previously put in your
config files. You then need to create an RVM wrapper in order for our RVM
environment to be loaded from any script we run.  This is done with

```
rvm alias create my_project ruby-VERSION@GEMSET
```

with `my_project` replaced with your project name and `VERSION` and `GEMSET`
replaced with the appropriate values identical to your `Gemfile` and `.rvmrc`.
This will create a wrapper at `/path/to/.rvm/wrappers/my_project`, and any
commands prefaced with that wrapper will be done with your Ruby environment
available.  If you're not sure where the rvm directory is, use `which rvm`, but
it will usually be at `/home/username/.rvm` or `/usr/local/rvm`.


### Git
First, `apt-get install git` if it isn't already present.  

You then need to create a fixed target for your Git pushes.  Create a directory
at `/var/repo/my_project.git/`, replacing 'my_project' as usual, and
`git init --bare` from inside it.  Inside the `hooks` directory you'll want to
create a file called `post-receive`, which can contain actions to take every
time a push is received.  You need to add the following lines:

```bash
#!/bin/bash
PROJECT_HOME=/chosen/path/to/project
GIT_TARGET=/var/repo/my_project.git
PROJECT_WRAPPER=/path/to/.rvm/wrappers/my_project

git --work-tree=${PROJECT_HOME} --git-dir=${GIT_TARGET} checkout -f
cd ${PROJECT_HOME}
${PROJECT_WRAPPER}/bundle install --deployment

```

Replace the paths for `PROJECT_HOME` and `GIT_TARGET` and `PROJECT_WRAPPER` to
match yours and save the file. You then need to `chmod +x post-receive` to make
it executable.

Back on your local machine, you need to add this target as a new remote for your
repository:

```
git remote add live ssh://user@domain.com/var/repo/my_project.git
```

replacing 'user', 'domain', and 'my_project' as appropriate.

With this addition, anytime we `git push live master`, the files will end up in
our project directory on the server and `bundle install --deployment`.  Will be
run to make sure our gems are updated.  If we change our project's directory in
future, we can just fix the hook file and keep using the same push target.  Go
ahead and push now so our project files are ready to go on the server.


### Nginx
`apt-get install nginx` to start, and then delete the default configuration file
at `/etc/nginx/sites-available/default`.  You're going to leave Nginx's main
config file alone to preserve the defaults there and just override the settings
needed to by creating an alias for the `nginx.conf` file we have in our repo:

```bash
ln -s /chosen/path/to/project/nginx.conf /etc/nginx/conf.d/default.conf
```

All you have to do then is `service nginx restart` and Nginx setup is done!


### Upstart
The final piece of the puzzle to getting your site deployed is creating an init
service so that Unicorn comes up whenever your server is restarted.  Here's
where things get sticky if you're using a distro other than Ubuntu for your
server: init systems vary and yours may use sys-v or systemd instead of Upstart.

Upstart init scripts are stored in `/etc/init`, so you're going to create a
`.conf` file there with an appropriate name (e.g. `my_project_unicorn.conf`) and
the following:

```
description "my_project unicorn daemon"

start on filesystem or runlevel [2345]
stop on shutdown

script

    cd /chosen/path/to/project
   /path/to/.rvm/wrappers/my_project/bundle exec unicorn -D -c unicorn.rb

end script

respawn
```

using the same wrapper used in the Git hook setup.  The script loads our
environment and then starts Unicorn in Daemon (-D) mode with our config file and
our gems loaded by bundle, while the rest handles starting and stopping our
service when the server comes up or goes down and restarting it if it crashes.

You can test the service with `service my_project_unicorn start`, and by
restarting the server and then checking with `ps aux | grep [u]nicorn` for the
unicorn master and worker processes.


## Conclusion
That's it!  Your site is live and you're ready to flesh it out through continual
deployment via Git without ever having to restart services.

I won't cover all the details of building a Sinatra application, please check
out [their own guide](http://www.sinatrarb.com/intro.html), but it's extremely
simple and straightforward.

Be sure to check out the [repository](https://github.com/rakelley/rakelley)
for this website for an example if you're unclear on anything.


## Additional Tricks and Notes
If you want Github-style triple-tick code blocks in your markdown, replace the
`markdown` gem with `redcarpet` in your `Gemfile` and add `:ugly => true` to
your HAML options, e.g.

```ruby
set :haml, :format => :html5, :ugly => true`
```

in your application to prevent HAML from messing up the whitespace in your code
blocks.

If you have a more complex or high traffic site or just a desire for a more
robust deployment system and server, you might want to investigate
[Capistrano](http://capistranorb.com/) and
[Passenger](https://www.phusionpassenger.com/).


## Resources
- [Setting up a new Ubuntu server](https://www.digitalocean.com/community/tutorial_series/new-ubuntu-14-04-server-checklist)
- [Setting up Git deployment](https://www.digitalocean.com/community/tutorials/how-to-set-up-automatic-deployment-with-git-with-a-vps)
- [Setting up Rails/Unicorn/Nginx on Ubuntu](https://www.digitalocean.com/community/tutorials/how-to-deploy-a-rails-app-with-unicorn-and-nginx-on-ubuntu-14-04)
- [Sinatra Manual](http://www.sinatrarb.com/intro.html)
- [RVM Manual](https://rvm.io/)
