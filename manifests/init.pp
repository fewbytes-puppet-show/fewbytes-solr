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
	$enable_service = false, # for upstart
	$activate_service = true,
	$zk_hosts=[],
	$data_dir=undef,
	$java_extra_opts="",
	$log_level=$::solr::params::log_level,
	$enable_requests_log=true,
	$init_style=sysv
) inherits solr::params {
	include java
	
	solr::instance{main:
		enable_service => $enable_service,
		activate_service => $activate_service,
		port => 8983,
		java_extra_opts => $java_extra_opts,
		enable_requests_log => $enable_requests_log,
		init_style => $init_style,
		log_level => $log_level,
		zk_hosts => $zk_hosts,
		data_dir => $data_dir
	}
}
