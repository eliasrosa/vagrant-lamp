# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  # define a box
  config.vm.box = "ubuntu/trusty32"

  # configura a rede
  config.vm.network "private_network", ip: "192.168.33.22"
  config.vm.network "public_network", bridge: 'wlan0'
  
  # sync a pasta com o servidor
  config.vm.synced_folder "./", "/var/www/html"

  # 
  config.vm.provision :shell, path: "./vagrant-lamp/scripts/bootstrap.sh"
  config.vm.provision :shell, run: "always", :path => "./vagrant-lamp/scripts/always.sh"

end
