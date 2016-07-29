# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

PG_DATABASE_NAME = "replication"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "ubuntu/trusty64"

# config.ssh.private_key_path = "/home/boria/.ssh/id_rsa"

  config.vm.define "alpha", primary: true do |server|
    server.vm.hostname = "alpha.pg"
    server.vm.network "private_network", ip: "192.168.4.2"
    config.vm.synced_folder "setup", "/setup"
    server.vm.provision "shell", path: "scripts/alpha.sh", args: PG_DATABASE_NAME
  end

  config.vm.define "beta" do |server|
    server.vm.hostname = "beta.pg"
    server.vm.network "private_network", ip: "192.168.4.3"  
    config.vm.synced_folder "setup", "/setup"
    server.vm.provision "shell", path: "scripts/beta.sh", args: PG_DATABASE_NAME
  end

end

