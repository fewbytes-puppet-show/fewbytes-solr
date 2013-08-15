class solr::first_run(
	$zk_host
	) {
	include solr::params
	exec{"java -classpath example/solr-webapp/WEB-INF/lib/* org.apache.solr.cloud.ZkCLI -cmd bootstrap -zkhost 127.0.0.1:9983 -solrhome example/solr":
		provider => shell,
		cwd => ${solr::params::solr_home}
	}
}