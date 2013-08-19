# Solr puppet module

This is the solr-cloud Puppet module. It installs and configures Solr 4.x instances. 

# Usage
To install a single instance of solr on port 8983 (default) use the `solr` class. e.g.:

    class{solr: zk_hosts => ["192.168.23.54:2181,192.168.23.44:2181,192.168.23.45:2181"]}

For multi-instance setup use the `solr::instance` definition:

    solr::instance{"first": port => 8983, zk_hosts => $zk_hosts}
    solr::instance{"second": port => 8984, zk_hosts => $zk_hosts}

`solr` class params: TODO
`solr::instance` params: TODO

License
-------
Apache V2

Support
-------

Please log tickets and issues at our [Projects site](https://github.com/fewbytes-puppet-show/fewbytes-solr)
