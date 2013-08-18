define solr::jetty_home($jetty_dir=$title) {
	include solr::params

	file{$jetty_dir: 
		ensure => directory,
		mode => 644
	}
	file{"${jetty_dir}/etc": 
		ensure => link,
		target => "${solr::params::base_dir}/current/example/etc",
	}
	file{"${jetty_dir}/contexts": 
		ensure => link,
		target => "${solr::params::base_dir}/current/example/contexts",
	}
	file{"${jetty_dir}/webapps": 
		ensure => link,
		target => "${solr::params::base_dir}/current/example/webapps",
	}
	file{"${jetty_dir}/lib":
		ensure => link,
		target => "${solr::params::base_dir}/current/example/lib",
	}
	file{"${jetty_dir}/start.jar":
		ensure => link,
		target => "${solr::params::base_dir}/current/example/start.jar",
	}
	file{"${jetty_dir}/solr-webapp":
		ensure => directory,
		owner => $solr::params::user,
		mode => 644
	}
}