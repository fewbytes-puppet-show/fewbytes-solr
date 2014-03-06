class solr::params {
	$var_dir="/var/lib/solr"
	$logs_dir="/var/log/solr"
	$user="solr"
	$log_level="info"
	$base_dir = "/opt/solr"
	$conf_dir = "/etc/solr"
	$jetty_dir = "${var_dir}/jetty"
	$solr_home_parent="${var_dir}/solr"
	$solr_home="${solr_home_parent}/home"
	$data_dir = "${solr_home}/data"
	$java_xmx="512m"
	$java_xmn="256m"
	$java_xms="512m"
	$java_extra_opts=""
	$max_threads=1000
	$min_threads=100
	$tarball_url="http://www.us.apache.org/dist/lucene/solr/4.7.0/solr-4.7.0.tgz"
}
