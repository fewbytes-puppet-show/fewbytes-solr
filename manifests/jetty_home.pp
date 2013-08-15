class solr::jetty_home {
	include solr::params

	file{"${solr::params::jetty_dir}/etc": 
		ensure => link,
		target => "${solr::params::base_dir}/current/example/etc",
	}
	file{"${solr::params::jetty_dir}/contexts": 
		ensure => link,
		target => "${solr::params::base_dir}/current/example/contexts",
	}
	file{"${solr::params::jetty_dir}/webapps": 
		ensure => link,
		target => "${solr::params::base_dir}/current/example/webapps",
	}
	file{"${solr::params::jetty_dir}/lib":
		ensure => link,
		target => "${solr::params::base_dir}/current/example/lib",
	}
	file{"${solr::params::jetty_dir}/start.jar":
		ensure => link,
		target => "${solr::params::base_dir}/current/example/start.jar",
	}
	file{"${solr::params::jetty_dir}/solr-webapp":
		ensure => directory,
		owner => $solr::params::user,
		mode => 644
	}
}