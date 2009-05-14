namespace :firewall do

  desc "Setup a default firewall configuration."
  task :setup, :roles => :gateway do
    enable_logging
    sudo "ufw default deny"
    open_firewall_port(ssh_options[:port] || 22)
    enable
  end

  desc "Enable the firewall `ufw enable`."
  task :enable do
    sudo_and_watch_prompt("ufw enable", /\(y\|n\)\?/)
  end

  desc "Disable the firewall `ufw disable`."
  task :disable do
    sudo "ufw disable"
  end

  desc "Enable firewall logging `ufw logging on`."
  task :enable_logging do
    sudo "ufw logging on"
  end

  desc "Disable firewall logging `ufw logging off`."
  task :disable_logging do
    sudo "ufw logging off"
  end

  # Given a port and protocol (default = tcp), open a port in the firewall.
  def open_firewall_port (port, protocol = 'tcp')
    sudo "ufw allow #{ "proto #{protocol} " if (protocol != 'both') }from any to any port #{port}"
  end

  desc "Open a port in the firewall."
  task :open_port do
    port = Capistrano::CLI.ui.ask("Which port do you want opened? ")
    protocol = Capistrano::CLI.ui.ask("Which protocol tcp, udp or both? ")
    open_firewall_port(port, protocol)
  end

  desc <<-DESC
    Set the logging level of the firewall. Valid levels are: 'off', 'low', 'medium', 'high' and 'full'.

    off    disables ufw managed logging
    low    logs all blocked packets not matching the default policy (with rate limiting), as well as packets matching logged rules
    medium log  level  low, plus all allowed packets not matching the default policy, all INVALID packets, and all new connections.
           All logging is done with rate limiting.
    high   log level medium (without rate limiting), plus all packets with rate limiting
    full   log level high without rate limiting
  DESC
  task :set_logging_level do
    level = Capistrano::CLI.ui.ask("What level of logging do you want (off|low|medium|high|full)? ")
    sudo "ufw logging #{level}"
  end

  desc "Get the firewall status `ufw status`."
  task :status do
    sudo "ufw status"
  end

end
