namespace :network do

  desc "Setup the network interface and DNS."
  task :setup do
    setup_network_interface
    setup_dns
    # TODO: setup hosts.allow and hosts.deny
  end

  desc "Configure the network interface."
  task :setup_network_interface do
    ip_address = nil
    while (ip_address != 'dhcp' &&
           !(ip_address =~ /\A(?:25[0-5]|(?:2[0-4]|1 \d|[1-9])?\d)(?:\.(?:25[0-5]|(?:2[0-4]|1\d|[1-9])?\d)){3}\z/))
      puts "That doesn't seem to be a valid IP address." if (!ip_address.nil?)
      ip_address = Capistrano::CLI.ui.ask("Static IP address (hint: 'dhcp' is an option): ")
    end

    if (ip_address != 'dhcp')
      ip_base = ip_address.split(/((\d+)\.(\d+)\.(\d+)\.)(\d+)/)[1]
      netmask = Capistrano::CLI.ui.ask("Netmask (default = 255.255.255.0): ")
      netmask = "255.255.255.0" if (netmask.empty?)
      broadcast = Capistrano::CLI.ui.ask("Broadcast IP address (default = #{ip_base}255): ")
      broadcast = "#{ip_base}255" if (broadcast.empty?)
      gateway = Capistrano::CLI.ui.ask("Gateway IP address (default = #{ip_base}1): ")
      gateway = "#{ip_base}1" if (gateway.empty?)
    end

    tmp_file = "interfaces.tmp"
    put render("interfaces", binding), tmp_file
    # perform this as one step to prevent interruption by a modified network interface
    sudo "mv /etc/network/interfaces /etc/network/interfaces.bak && \ " +
         "sudo mv #{tmp_file} /etc/network/interfaces"
    sudo "chown root:root /etc/network/interfaces"
    # TODO: there is some funkyness where restart may hang when switching ip addresses
    # All changes are applied to the server but, since the IP address changes, capistrano doesn't receive notification.
    restart
    puts "Don't forget to update 'server_name' in your config/deploy.rb file if necessary!"

    # If this task is called as part of another script, changing the ip address
    # will interrupt the execution of that script. If the user has entered a static
    # address we persist that information to allow the current script to complete.
    set :server_name, ip_address if (ip_address != 'dhcp')
  end

  desc "Setup DNS on the server."
  task :setup_dns do
    domain = Capistrano::CLI.ui.ask("What domain should we use for this host: ")
    search_domains = Capistrano::CLI.ui.ask("Search domains (multiples values separated by a space): ")
    nameservers = []
    (1..3).each do
      ns = Capistrano::CLI.ui.ask("Nameserver IP address: ")
      break if (ns.empty?)
      nameservers << ns
    end

    tmp_file = "resolv.conf.tmp"
    put render("resolv.conf", binding), tmp_file
    sudo "mv /etc/resolv.conf /etc/resolv.conf.bak && #{sudo} mv #{tmp_file} /etc/resolv.conf"
    sudo "chown root:root /etc/resolv.conf"
    # restart
  end

  desc "Restart network interface"
  task :restart do
    sudo "/etc/init.d/networking restart < /dev/null > /dev/null 2>&1 &"
  end

end
