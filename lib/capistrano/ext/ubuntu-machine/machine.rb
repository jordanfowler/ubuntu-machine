namespace :machine do

  desc <<-DESC
    Designed to be run immediately after installation of a new server.
    This task will setup ssh and a firewall. It will also configure
    network settings. Finally the task will check for software updates
    and install a handful of base packages which will assist in
    building other software packages.
  DESC
  task :initial_setup do
    ssh.setup
    firewall.setup
    network.setup
    aptitude.setup
  end

  task :configure do
    git.install
    if (exists? 'dotfiles_git_repos')
      run "rm -rf dotfiles; git clone #{dotfiles_git_repos} dotfiles"
      run_and_watch_prompt "cd dotfiles && rake install", /\? \[ynaq\]/
      sudo "ln -fs ~/.forward /root/."
    end

    # TODO: Setup backup scripts
    # TODO: Setup log rotation
    # TODO: setup logcheck/logwatch
    # TODO: setup ddclient?
  end

  task :install_software do
    mysql.install

    apache.install
    sudo "ln -s /var/www ."
    open_firewall_port(80)
    open_firewall_port(443)

    postfix.install
    ruby.install
    gems.install_rubygems
    ruby.install_enterprise
    ruby.install_passenger
    php.install
  end

  desc = "Ask for a user and change his password"
  task :change_password do
    user_to_update = Capistrano::CLI.ui.ask("Name of the user whose password you want to update : ")

    run_and_watch_prompt("passwd #{user_to_update}", [/Enter new UNIX password/, /Retype new UNIX password:/])
  end

end
