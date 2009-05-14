namespace :gems do

  desc "Install RubyGems from source."
  task :install_rubygems, :roles => :app do
    run "wget http://rubyforge.org/frs/download.php/45905/rubygems-#{rubygem_version}.tgz"
    run "tar xvzf rubygems-#{rubygem_version}.tgz"
    run "cd rubygems-#{rubygem_version} && sudo ruby setup.rb"
    sudo "ln -fs /usr/bin/gem1.8 /usr/bin/gem"
    sudo "gem update"
    sudo "gem update --system"
    run "rm -Rf rubygems-#{rubygem_version}*"
  end

  desc "List gems on remote server"
  task :list, :roles => :app do
    stream "gem list"
  end

  desc "Update gems on remote server"
  task :update, :roles => :app do
    sudo "gem update"
  end

  desc "Update gem system on remote server"
  task :update_system, :roles => :app do
    sudo "gem update --system"
  end

  desc "Install a gem on the remote server"
  task :install, :roles => :app do
    name = Capistrano::CLI.ui.ask("Which gem should we install: ")
    sudo "gem install #{name}"
  end

  desc "Uninstall a gem on the remote server"
  task :uninstall, :roles => :app do
    name = Capistrano::CLI.ui.ask("Which gem should we uninstall: ")
    sudo "gem uninstall #{name}"
  end

end
