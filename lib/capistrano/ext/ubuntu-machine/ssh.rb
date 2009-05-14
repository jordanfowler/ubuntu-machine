namespace :ssh do

  desc <<-DESC
    Setup SSH on the gateway host. Runs `upload_keys` and `configure_sshd`.
  DESC
  task :setup, :roles => :gateway do
    upload_keys
    configure_sshd
  end

  desc <<-DESC
    Uploads your local public SSH keys to the server. A .ssh folder is created if \
    one does not already exist. The SSH keys default to the ones set in \
    Capistrano's ssh_options. You can change this by setting ssh_options[:keys] = \
    ["/home/user/.ssh/id_dsa"].

    See "SSH copy" and "SSH Permissions" sections on \
    http://articles.slicehost.com/2008/4/25/ubuntu-hardy-setup-page-1
  DESC
  task :upload_keys, :roles => :gateway do
    run "mkdir -p ~/.ssh"
    run "chown -R #{user}:#{user} ~/.ssh"
    run "chmod 700 ~/.ssh"

    authorized_keys = ssh_options[:keys].collect { |key| File.read("#{key}.pub") }.join("\n")
    put authorized_keys, "./.ssh/authorized_keys", :mode => 0600
  end

  desc <<-DESC
    Configure SSH daemon the settings specified in the sshd_config template. \
    This method will prompt to see whether the ssh port should be modified. \
    Note that this method will automatically call `cap ssh:reload` so that changes \
    are applied.

    See "SSH config" section on \
    http://articles.slicehost.com/2008/4/25/ubuntu-hardy-setup-page-1
  DESC
  task :configure_sshd, :roles => :gateway do
    port = Capistrano::CLI.ui.ask("If you would like for SSH to use a different port, specify it here (press Enter to skip) : ")
    @new_ssh_port = (port.to_i > 0) ? port.to_i : nil
    if (!@new_ssh_port.nil?)
      puts "The SSH port will be changed. Don't forget to update 'ssh_options[:port]' in your config/deploy.rb file!"
    end

    put render("sshd_config", binding), "sshd_config"
    sudo "mv sshd_config /etc/ssh/sshd_config"
    reload
  end

  desc <<-DESC
    Reload SSH service.
  DESC
  task :reload, :roles => :gateway do
    sudo "/etc/init.d/ssh reload"

    # when this task is called automatically from `configure_sshd` there is a possiblity
    # that the user has changed which port sshd uses. In that case we persist the
    # user's change so that the current script will continue to successfully execute.
    ssh_options[:port] = @new_ssh_port if (@new_ssh_port)
  end

end
