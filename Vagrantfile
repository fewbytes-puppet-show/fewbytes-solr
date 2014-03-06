# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # All Vagrant configuration is done here. The most common configuration
  # options are documented and commented below. For a complete reference,
  # please see the online documentation at vagrantup.com.

  config.vm.network :forwarded_port, :guest => 8983, :host => 8983
  # Every Vagrant virtual environment requires a box to build off of.
  config.vm.box = "opscode-centos-6.5"
  config.vm.provision :shell, :inline => <<-EOS
if ! which puppet>/dev/null; then
  sudo rpm -ivh http://yum.puppetlabs.com/el/6/products/x86_64/puppetlabs-release-6-7.noarch.rpm
  yum install -y puppet
fi
  EOS
  config.vm.provision :puppet do |puppet|
    puppet.manifests_path = "tests"
    puppet.module_path = "/tmp/puppet-solr"
    puppet.manifest_file  = "init.pp"
    #puppet.options = "--hiera_config /vagrant/hiera.yaml"
  end

  config.vm.provider :virtualbox do |vb|
     vb.customize ["modifyvm", :id, "--memory", "1024"]
     vb.customize ['storagectl', :id, '--name', 'IDE Controller', '--hostiocache', 'on']
     vb.customize ['storagectl', :id, '--name', 'IDE Controller', '--controller', 'ICH6']
     vb.customize ['modifyvm', :id, "--chipset", "ich9"]
  end
end
