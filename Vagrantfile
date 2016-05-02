# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure(2) do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://atlas.hashicorp.com/search.
  config.vm.box = "ubuntu/trusty64"

  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  # config.vm.box_check_update = false

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  # config.vm.network "forwarded_port", guest: 80, host: 8080

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  config.vm.network "private_network", ip: "192.168.56.133"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network "public_network"

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  # config.vm.provider "virtualbox" do |vb|
  #   # Display the VirtualBox GUI when booting the machine
  #   vb.gui = true
  #
  #   # Customize the amount of memory on the VM:
  #   vb.memory = "1024"
  # end
  #
  # View the documentation for the provider you are using for more
  # information on available options.

  # Define a Vagrant Push strategy for pushing to Atlas. Other push strategies
  # such as FTP and Heroku are also available. See the documentation at
  # https://docs.vagrantup.com/v2/push/atlas.html for more information.
  # config.push.define "atlas" do |push|
  #   push.app = "YOUR_ATLAS_USERNAME/YOUR_APPLICATION_NAME"
  # end

  # Enable provisioning with a shell script. Additional provisioners such as
  # Puppet, Chef, Ansible, Salt, and Docker are also available. Please see the
  # documentation for more information about their specific syntax and use.
  config.vm.provision "shell", inline: <<-SHELL
      export DEBIAN_FRONTEND=noninteractive

      sudo locale-gen ru_RU.UTF-8 && \
      sudo update-locale LANG=en_US.UTF-8 \
                         LANGUAGE=ru_RU.UTF-8 \
                         LC_CTYPE="en_US.UTF-8" \
                         LC_NUMERIC=ru_RU.UTF-8 \
                         LC_TIME=ru_RU.UTF-8 \
                         LC_COLLATE="en_US.UTF-8" \
                         LC_MONETARY=ru_RU.UTF-8 \
                         LC_MESSAGES="en_US.UTF-8" \
                         LC_PAPER=ru_RU.UTF-8 \
                         LC_NAME=ru_RU.UTF-8 \
                         LC_ADDRESS=ru_RU.UTF-8 \
                         LC_TELEPHONE=ru_RU.UTF-8 \
                         LC_MEASUREMENT=ru_RU.UTF-8 \
                         LC_IDENTIFICATION=ru_RU.UTF-8 \
                         LC_ALL=ru_RU.UTF-8 && \

      curl -sS http://obs.devbanki.ru:82/ourkeyfile.asc | sudo apt-key add - && \

      echo -n '' > /etc/apt/sources.list.d/bankiru.list && \

      echo 'deb http://obs.devbanki.ru:82/bankiru:/contrib/xUbuntu_14.04 ./'                 >> /etc/apt/sources.list.d/bankiru.list && \
      echo 'deb [arch=amd64] http://repo.devbanki.ru/ubuntu/ trusty main restricted'         >> /etc/apt/sources.list.d/bankiru.list && \
      echo 'deb-src http://repo.devbanki.ru/ubuntu/ trusty main restricted'                  >> /etc/apt/sources.list.d/bankiru.list && \
      echo 'deb [arch=amd64] http://repo.devbanki.ru/ubuntu/ trusty-updates main restricted' >> /etc/apt/sources.list.d/bankiru.list && \
      echo 'deb-src http://repo.devbanki.ru/ubuntu/ trusty-updates main restricted'          >> /etc/apt/sources.list.d/bankiru.list && \
      echo 'deb [arch=amd64] http://repo.devbanki.ru/ubuntu/ trusty universe'                >> /etc/apt/sources.list.d/bankiru.list && \
      echo 'deb-src http://repo.devbanki.ru/ubuntu/ trusty universe'                         >> /etc/apt/sources.list.d/bankiru.list && \
      echo 'deb [arch=amd64] http://repo.devbanki.ru/ubuntu/ trusty-updates universe'        >> /etc/apt/sources.list.d/bankiru.list && \
      echo 'deb-src http://repo.devbanki.ru/ubuntu/ trusty-updates universe'                 >> /etc/apt/sources.list.d/bankiru.list && \
      echo 'deb [arch=amd64] http://repo.devbanki.ru/ubuntu/ trusty multiverse'              >> /etc/apt/sources.list.d/bankiru.list && \
      echo 'deb-src http://repo.devbanki.ru/ubuntu/ trusty multiverse'                       >> /etc/apt/sources.list.d/bankiru.list && \
      echo 'deb [arch=amd64] http://repo.devbanki.ru/ubuntu/ trusty-updates multiverse'      >> /etc/apt/sources.list.d/bankiru.list && \
      echo 'deb-src http://repo.devbanki.ru/ubuntu/ trusty-updates multiverse'               >> /etc/apt/sources.list.d/bankiru.list && \
      echo 'deb [arch=amd64] http://repo.devbanki.ru/ubuntu trusty-security main restricted' >> /etc/apt/sources.list.d/bankiru.list && \
      echo 'deb-src http://repo.devbanki.ru/ubuntu trusty-security main restricted'          >> /etc/apt/sources.list.d/bankiru.list && \
      echo 'deb [arch=amd64] http://repo.devbanki.ru/ubuntu trusty-security universe'        >> /etc/apt/sources.list.d/bankiru.list && \
      echo 'deb-src http://repo.devbanki.ru/ubuntu trusty-security universe'                 >> /etc/apt/sources.list.d/bankiru.list && \
      echo 'deb [arch=amd64] http://repo.devbanki.ru/ubuntu trusty-security multiverse'      >> /etc/apt/sources.list.d/bankiru.list && \
      echo 'deb-src http://repo.devbanki.ru/ubuntu trusty-security multiverse'               >> /etc/apt/sources.list.d/bankiru.list && \

      sudo apt-get update && \
      sudo apt-get install -y mc nginx-extras lua-cjson inotify-tools

      sudo mkdir -p /etc/nginx/metrix

      echo "* * * * * /vagrant/rsync.sh" | sudo crontab -u root -
  SHELL
end
