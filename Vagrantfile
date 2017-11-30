#16.04
box = "bento/ubuntu-16.04"

# Settings for all boxes:
Vagrant.configure("2") do |config|
    config.vm.box = box
    config.vm.provider "virtualbox" do |v|
      v.gui = true
      v.customize ["modifyvm", :id, "--ostype", "Ubuntu_64"]
      v.customize ["modifyvm", :id, "--memory", "4096"]
      v.customize ["modifyvm", :id, "--vram", "16"]
      v.customize ["modifyvm", :id, "--clipboard", "bidirectional"]
    end

  config.vm.define "vb-01" do |config|
    config.vm.host_name = "server-waarneming-db"
    config.vm.network "forwarded_port", id: 'ssh', guest: 22, host: 2222
    config.vm.network "private_network", ip: "192.168.56.5"
    config.vm.provision "shell",
      inline: "curl https://raw.githubusercontent.com/rudibroekhuizen/puppet-role_base/master/files/bootstrap.sh > bootstrap.sh; chmod +x bootstrap.sh;./bootstrap.sh server-waarneming-db"
  end

  config.vm.define "vb-02" do |config|
    config.vm.host_name = "server-waarneming-db-slave"
    config.vm.network "forwarded_port", id: 'ssh', guest: 22, host: 2223
    config.vm.network "private_network", ip: "192.168.56.6"
    config.vm.provision "shell",
      inline: "curl https://raw.githubusercontent.com/rudibroekhuizen/puppet-role_base/master/files/bootstrap.sh > bootstrap.sh; chmod +x bootstrap.sh;./bootstrap.sh server-waarneming-db-slave"
  end

end
