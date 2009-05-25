require 'net/http'

namespace :git do

  desc "Install the latest version of git from source."
  task :install, :roles => :app do
    latest = latest_version
    if (current_version != latest)
      sudo "apt-get build-dep git-core -y"
      run "wget -q #{git_url}"
      run "tar xvzf git-#{latest}.tar.gz"
      run "cd git-#{latest} && auto-apt run ./configure && make"
      run "cd git-#{latest} && #{sudo} checkinstall -y"
      sudo "rm -rf git-#{latest}"
      run "rm git-#{latest}.tar.gz"
    end
  end

  desc "Remove git from the server."
  task :uninstall do
    sudo "dpkg -r git"
  end

  desc "Alias for git:install."
  task :update do
    install
  end

  # Gets the version of git which is currently installed on the server.
  set :current_version do
    begin
      out = capture "git --version"
      out.split(/((\d\.?)+$)/)[1]
    rescue # if git isn't installed
      "0.0.0"
    end
  end

  # Gets the most recently released version of git.
  set :latest_version do
    git_url.split(/git-((\d\.?)+).tar\.gz/)[1]
  end

  # Gets the url to download the most recently released version of git.
  set :git_url do
    latest = Net::HTTP.get('kernel.org', '/pub/software/scm/git/').scan(/(git-(\d\.?)+.tar\.gz)/).last[0]
    "http://kernel.org/pub/software/scm/git/#{latest}"
  end

end
