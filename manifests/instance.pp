define solr::instance(
	$instance_name=$title,
	$activate_service=true,
	$enable_service=true,
	$port,
	$zk_hosts=[],
	$data_dir=undef,
	$java_xmx=$::solr::params::java_xmx,
	$java_xmn=$::solr::params::java_xmn,
	$java_xms=$::solr::params::java_xms,
	$java_extra_opts="",
	$log_level=$::solr::params::log_level,
	$max_threads=$::solr::params::max_threads,
	$min_threads=$::solr::params::min_threads,
	$enable_requests_log=true,
	$init_style=sysv
	) {

	include java
	include solr::install
	
	$instance_dir = "${solr::params::var_dir}/${instance_name}"
	
	if is_array($zk_hosts) and ! empty($zk_hosts) {
		$zk_hosts_str = join($zk_hosts, ",")
		$zk_opts = "-DzkHost=${zk_hosts_str}"
	}
	if $data_dir == undef {
		$data_dir_real = "${instance_dir}/data"
	} else {
		$data_dir_real = $data_dir
	}

	$log_dir = "${solr::params::logs_dir}/${instance_name}"
	$solr_home = "${instance_dir}/home"
	$jetty_dir = "${instance_dir}/jetty"
	$svc_name = "solr-${instance_name}"
	$conf_dir = "${solr::params::conf_dir}/${instance_name}"
	$java_heap_opts = "-Xmx${java_xmx} -Xmn${java_xmn} -Xms${java_xms} ${java_extra_opts}"
	$solr_opts = "-Dsolr.solr.home=${solr_home} -Dsolr.data.dir=${data_dir_real}"
	$java_opts = "$java_heap_opts -Djetty.port=${port} -Dlog4j.configuration=file://${conf_dir}/log4j.properties ${solr_opts} ${zk_opts}"

	file{[$conf_dir, $instance_dir]: 
		ensure => directory,
		mode => 644
	}

	file{[$log_dir, $solr_home, $data_dir_real]: 
		ensure => directory,
		owner => $solr::params::user,
		mode => 644,
		before => Service[$svc_name],
		require => User[$solr::params::user]
	}

	file{"${solr_home}/solr.xml":
		ensure => link,
		target => "${conf_dir}/solr.xml",
		notify => Service[$svc_name]
	}

	solr::jetty_home{$jetty_dir: before => Service[$svc_name], require => File["${solr::params::base_dir}/current"]}

	file{"${conf_dir}/solr.xml": 
		content => template("solr/solr.xml.erb"),
		mode => 644,
		notify => Service[$svc_name]
	}
	file{"${conf_dir}/log4j.properties":
		content => template("solr/log4j.properties.erb"),
		mode => 644,
		notify => Service[$svc_name]
	}

	file{"${conf_dir}/jetty.xml":
		content => template("solr/jetty.xml.erb"),
		mode => 644,
		notify => Service[$svc_name]
	}

	exec{"cp -a ${solr::params::base_dir}/current/example/solr/collection1 ${solr_home}/ && chown -R ${solr::params::user} ${solr_home}/collection1": 
		provider => shell,
		before => Service[$svc_name],
		require => [Class[solr::install], File[$solr_home]],
		creates => "${solr_home}/collection1/core.properties"
	}

# ugly hack for upstart on RHEL 6.x
	case $init_style {
		upstart : {
			upstart::service{$svc_name:
				ensure => $activate_service,
				user => $user,
				chdir => $jetty_dir,
				exec => "java $java_opts -jar $jetty_dir/start.jar $conf_dir/jetty.xml",
				require => [Class[java], Class[solr::install]]
			}
		}
		sysv : {
			file{"/etc/init.d/${svc_name}":
				mode => 755,
				content => template("solr/init.sh.erb")
			} ->
			service{$svc_name: 
				ensure => $activate_service,
				enable => $enable_service,
				require => [Class[java], Class[solr::install]]
			}
		}
	}
}