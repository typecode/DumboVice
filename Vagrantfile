
# -*- mode: ruby -*-
# vi: set ft=ruby :

VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

    config.vm.define "dev", primary: true do |dev|
        dev.vm.box = "ubuntu/trusty64"
        dev.vm.box_url = 'https://vagrantcloud.com/ubuntu/boxes/trusty64/versions/14.04/providers/virtualbox.box'

        
        dev.vm.provider :virtualbox do |vb|
            vb.gui = true
            vb.customize ["modifyvm", :id, "--memory", "1024"]
        end

        dev.vm.provision "shell", path: "vagrant/provision.sh"
    end

end
