# Elasticsearch

elasticsearch_1  | ERROR: [2] bootstrap checks failed
elasticsearch_1  | [1]: max virtual memory areas vm.max_map_count [65530] is too low, increase to at least [262144]
elasticsearch_1  | [2]: the default discovery settings are unsuitable for production use; at least one of [discovery.seed_hosts, discovery.seed_providers, cluster.initial_master_nodes] must be configured

### max virtual memory areas vm.max_map_count [65530] is too low, increase to at least [262144]

Set vm.max_map_count to at least 262144

```
sysctl -w vm.max_map_count=262144
````

https://www.elastic.co/guide/en/elasticsearch/reference/7.6/docker.html

### the default discovery settings are unsuitable for production use; at least one of [discovery.seed_hosts, discovery.seed_providers, cluster.initial_master_nodes] must be configured

```
environment:
  discovery.type: single-node
```

https://stackoverflow.com/a/61547317
