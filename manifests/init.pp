# == Class: solr-cloud
#
# Full description of class solr-cloud here.
#
# === Parameters
#
# Document parameters here.
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
# === Variables
#
# Here you should define a list of variables that this module would require.
#
# [*sample_variable*]
#   Explanation of how this variable affects the funtion of this class and if it
#   has a default. e.g. "The parameter enc_ntp_servers must be set by the
#   External Node Classifier as a comma separated list of hostnames." (Note,
#   global variables should not be used in preference to class parameters  as of
#   Puppet 2.6.)
#
# === Examples
#
#  class { solr:
#    version => 4.4.0,
#    enable_service => false,
#    activate_service => true,
#    zk_hosts => "192.168.1.2:2181"
#  }
#
# === Authors
#
# Author Name <avishai@fewbytes.com>
#
# === Copyright
#
# Copyright 2013 Fewbytes LTD, unless otherwise noted.
#
class solr( 
	$version="4.4.0",
	$tarball_url=$::solr::params::tarball_url,
	$enable_service = false, # for upstart
	$activate_service = true,
	$zk_hosts=[],
	$data_dir=$::solr::params::data_dir,
	$java_xmx=$::solr::params::java_xmx,
	$java_xmn=$::solr::params::java_xmn,
	$java_xms=$::solr::params::java_xms,
	$java_extra_opts="",
	$log_level=$::solr::params::log_level,
	$logs_dir=$::solr::params::logs_dir,
	$max_threads=$::solr::params::max_threads,
	$min_threads=$::solr::params::min_threads,
	$enable_requests_log=true,
	$init_style=sysv
) inherits solr::params {
	include java
	
	if is_array($zk_hosts) and ! empty($zk_hosts) {
		$zk_hosts_str = join($zk_hosts, ",")
		$zk_opts = "-DzkHost=${zk_hosts_str}"
	}
	$java_heap_opts = "-Xmx${java_xmx} -Xmn${java_xmn} -Xms${java_xms} ${java_extra_opts}"
	$solr_opts = "-Dsolr.solr.home=${solr::params::solr_home} -Dsolr.data.dir=${data_dir}"
	$java_opts = "$java_heap_opts -Dlog4j.configuration=file://${solr::params::conf_dir}/log4j.properties ${solr_opts} ${zk_opts}"
	
	user{$solr::params::user: ensure => present, system => true }
	file{[$base_dir,
		$conf_dir,
		$var_dir,
		$jetty_dir,
		"${base_dir}/${version}"]: 
		ensure => directory,
		mode => 644
	}
	
	if $tarball_url =~ /^puppet:\/\// {
		file {"/tmp/solr-$version.tar.gz":
			source => $solr::params::tarball_url,
			before => Exec["extract solr $version"]
		}
	} else {
		exec {"download solr $version":
			command => "/usr/bin/wget -O /tmp/solr-$version.tar.gz -nv ${tarball_url}",
			creates => "/tmp/solr-$version.tar.gz",
			before => Exec["extract solr $version"]
		}
	}
	exec {"extract solr $version":
		provider => shell,
		command => "tar -xzf /tmp/solr-$version.tar.gz -C ${solr::params::base_dir}/$version --strip-components=1",
		creates => "${solr::params::base_dir}/$version/example/start.jar",
		require => File["${solr::params::base_dir}/$version"]
	}
	->
	file{"${solr::params::base_dir}/current": 
		ensure => link,
		target => "${solr::params::base_dir}/$version",
		notify => Service[solr],
	}

	file{[$solr::params::logs_dir, $solr::params::solr_home]: 
		ensure => directory,
		owner => $solr::params::user,
		mode => 644,
		before => Service[solr],
		require => User[$solr::params::user]
	}

	file{"${solr_home}/solr.xml":
		ensure => link,
		target => "${conf_dir}/solr.xml",
		notify => Service[solr]
	}
	file{"${var_dir}/contrib": 
		ensure => link,
		target => "${base_dir}/current/contrib",
		before => Service[solr]
	}
	file{"${var_dir}/dist": 
		ensure => link,
		target => "${base_dir}/current/dist",
		before => Service[solr]
	}

	class{solr::jetty_home: before => Service[solr], require => File["${base_dir}/current"]}

	file{"${solr::params::conf_dir}/solr.xml": 
		content => template("solr/solr.xml.erb"),
		mode => 644,
		notify => Service[solr]
	}
	file{"${solr::params::conf_dir}/log4j.properties":
		content => template("solr/log4j.properties.erb"),
		mode => 644,
		notify => Service[solr]
	}

	file{"${solr::params::conf_dir}/jetty.xml":
		content => template("solr/jetty.xml.erb"),
		mode => 644,
		notify => Service[solr]
	}

	exec{"cp -a ${solr::params::base_dir}/current/example/solr/collection1 ${solr_home}/ && chown -R ${solr::params::user} ${solr_home}/collection1": 
		provider => shell,
		before => Service[solr],
		require => [Exec["extract solr $version"], File[$solr_home]],
		creates => "${solr_home}/collection1/core.properties"
	}

# ugly hack for upstart on RHEL 6.x
	case $init_style {
		upstart : {
			upstart::service{solr:
				ensure => $activate_service,
				user => $user,
				chdir => $jetty_dir,
				exec => "java $java_opts -jar $jetty_dir/start.jar $conf_dir/jetty.xml",
				require => Class[java]
			}
		}
		sysv : {
			file{"/etc/init.d/solr":
				mode => 755,
				content => template("solr/init.sh.erb")
			} ->
			service{solr: 
				ensure => $activate_service,
				enable => $enable_service,
				require => Class[java]
			}
		}
	}
}
