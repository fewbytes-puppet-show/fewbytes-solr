class solr::install(
	$version="4.7.0",
	$tarball_url=$::solr::params::tarball_url,
	$logs_dir=$::solr::params::logs_dir,
	$user=$::solr::params::user,
	$group=$::solr::params::group,
) inherits solr::params {
	group{$group: ensure => present, system => true}
	->
	user{$user: ensure => present, system => true, gid => $group }
	file{[$base_dir,
		$conf_dir,
		$var_dir,
		"${base_dir}/${version}"]: 
		ensure => directory,
		mode => 644
	}
	
	if $tarball_url =~ /^puppet:\/\// {
		file {"/tmp/solr-$version.tar.gz":
			source => $tarball_url,
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
		owner => $user,
		group => $group,
		mode => 644,
		require => [User[$user], Group[$group]]
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
