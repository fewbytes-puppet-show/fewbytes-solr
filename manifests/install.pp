class solr::install(
	$version="4.4.0",
	$tarball_url=$::solr::params::tarball_url,
	$logs_dir=$::solr::params::logs_dir,
) inherits solr::params {
	user{$solr::params::user: ensure => present, system => true }
	file{[$base_dir,
		$conf_dir,
		$var_dir,
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
	}

	file{$logs_dir: 
		ensure => directory,
		owner => $solr::params::user,
		mode => 644,
		require => User[$solr::params::user]
	}
	file{"${var_dir}/contrib": 
		ensure => link,
		target => "${base_dir}/current/contrib",
	}
	file{"${var_dir}/dist": 
		ensure => link,
		target => "${base_dir}/current/dist",
	}
}
