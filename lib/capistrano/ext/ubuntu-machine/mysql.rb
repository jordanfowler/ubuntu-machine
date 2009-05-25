# TODO: create a drop_db task

namespace :mysql do

  desc "Restarts MySQL database server"
  task :restart, :roles => :db do
    sudo "/etc/init.d/mysql restart"
  end

  desc "Starts MySQL database server"
  task :start, :roles => :db do
    sudo "/etc/init.d/mysql start"
  end

  desc "Stops MySQL database server"
  task :stop, :roles => :db do
    sudo "/etc/init.d/mysql stop"
  end

  desc "Get the status of the MySQL database server."
  task :status, :roles => :db do
    stream "#{sudo} /etc/init.d/mysql status"
  end

  set :datestamp do
    Time.now.strftime "%Y.%m.%d.%H%M%z"
  end

  desc "Create a new MySQL database and a new MySQL user. Optionally load a local MySQL dump file."
  task :create_database, :roles => :db do
    new_db_name = Capistrano::CLI.ui.ask("New database name: ")
    root_db_password = Capistrano::CLI.ui.ask("MySQL root password: ")
    root_db_password = "-p#{root_db_password}" if (!root_db_password.empty?)
    new_db_user = Capistrano::CLI.ui.ask("New MySQL username: ")
    new_user_db_password = Capistrano::CLI.ui.ask("New password for MySQL user #{new_db_user}: ")

    create_db_tmp_file = "create_#{new_db_name}.sql"
    put render("new_db", binding), create_db_tmp_file
    run "cat #{create_db_tmp_file} | mysql -uroot #{root_db_password}"
    run "rm #{create_db_tmp_file}"

    do_import_file = Capistrano::CLI.ui.ask("Do you want to import a database file? (y/n): ")
    if (do_import_file == "y" || do_import_file == "yes")
      file = Capistrano::CLI.ui.ask("Which database file should we import: ")
      sql_bup_file = File.new("#{default_local_files_path}/#{file}") if (File.exists?("#{default_local_files_path}/#{file}"))
      sql_bup_file = File.new(file) if (!sql_bup_file && File.exists?(file))
      upload sql_bup_file.path.to_s, "#{File.basename(sql_bup_file.path.to_s)}"

      case File.extname(sql_bup_file.path.to_s)
        when '.gz', '.Z'
          load_cmd = 'zcat'
        when '.bz2'
          load_cmd = 'bzcat'
        else
          load_cmd = 'cat'
      end
      load_cmd = "#{load_cmd} #{File.basename(sql_bup_file.path.to_s)} | mysql -uroot #{root_db_password} #{new_db_name}"
      run "#{load_cmd}"
      run "rm #{File.basename(sql_bup_file.path.to_s)}"
    end
  end

  desc "Backup a MySQL database. The backup is saved in :default_local_files_path."
  task :backup, :roles => :db do
    database = Capistrano::CLI.ui.ask("Name of the database you want to backup : ")

    root_db_password = Capistrano::CLI.ui.ask("MySQL root password : ")
    date = datestamp
    bup_name = "#{server_name}_#{database}_#{date}.sql.gz"

    run "mysqldump -u root #{'-p' + root_db_password if (!root_db_password.empty?)} #{database} | gzip --best -c > #{bup_name}"
    download "#{bup_name}", "#{default_local_files_path}/#{bup_name}"
    run "rm #{bup_name}"
  end

  desc "Install MySQL and optionally set a root password."
  task :install, :roles => :db do
    root_db_password = Capistrano::CLI.ui.ask("Choose a MySQL root password : ")

    sudo "apt-get install -y mysql-server mysql-client libmysqlclient15-dev"
    run "mysqladmin -u root password #{root_db_password}" if (!root_db_password.empty?)
  end

  desc "Ask for a MySQL user and change his password"
  task :change_password, :roles => :db do
    user_to_update = Capistrano::CLI.ui.ask("Name of the MySQL user whose password you want to update : ")
    old_password = Capistrano::CLI.ui.ask("Old password for #{user_to_update} : ")
    new_password = Capistrano::CLI.ui.ask("New password for #{user_to_update} : ")

    run "mysqladmin -u #{user_to_update} #{'-p' + old_password if (!old_password.empty?)} password \"#{new_password}\""
  end

end
