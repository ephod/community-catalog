version: '2'
services:
    es-master:
        labels:
            io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
            io.rancher.container.hostname_override: container_name
            io.rancher.sidekicks: es-master-storage{{- if eq .Values.UPDATE_SYSCTL "true" -}},es-master-sysctl{{- end}}
        image:  docker.elastic.co/elasticsearch/elasticsearch:7.0.1
        environment:
            - "cluster.name=${cluster_name}"
            - "node.name=$${HOSTNAME}"
            - "bootstrap.memory_lock=true"
            - "ES_JAVA_OPTS=-Xms${master_heap_size} -Xmx${master_heap_size}"
            - "cluster.initial_master_nodes=${cluster_name}"
            - "node.master=true"
            - "node.data=false"
        ulimits:
            memlock:
                soft: -1
                hard: -1
            nofile:
                soft: 65536
                hard: 65536
        mem_limit: ${master_mem_limit}
        mem_swappiness: 0
        cap_add:
            - IPC_LOCK
        # healthcheck:
        #     test: ['CMD', 'curl', '-f', 'http://localhost:9200']
        #     interval: 10s
        #     timeout: 5s
        #     retries: 3
        volumes_from:
            - es-master-storage

    es-master-storage:
        labels:
            io.rancher.container.start_once: true
        network_mode: none
        image: rawmind/alpine-volume:0.0.2-3
        environment:
            - SERVICE_UID=1000
            - SERVICE_GID=1000
            - SERVICE_VOLUME=/usr/share/elasticsearch/data
        volumes:
            - es-master-volume:/usr/share/elasticsearch/data

    es-data:
        labels:
            io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
            io.rancher.container.hostname_override: container_name
            io.rancher.sidekicks: es-data-storage{{- if eq .Values.UPDATE_SYSCTL "true" -}},es-data-sysctl{{- end}}
        image: docker.elastic.co/elasticsearch/elasticsearch:7.0.1
        environment:
            - "cluster.name=${cluster_name}"
            - "node.name=$${HOSTNAME}"
            - "bootstrap.memory_lock=true"
            - "discovery.seed_hosts=es-master"
            - "ES_JAVA_OPTS=-Xms${data_heap_size} -Xmx${data_heap_size}"
            - "node.master=false"
            - "node.data=true"
        ulimits:
            memlock:
                soft: -1
                hard: -1
            nofile:
                soft: 65536
                hard: 65536
        mem_limit: ${data_mem_limit}
        mem_swappiness: 0
        cap_add:
            - IPC_LOCK
        # healthcheck:
        #     test: ['CMD', 'curl', '-f', 'http://localhost:9200']
        #     interval: 10s
        #     timeout: 5s
        #     retries: 3
        volumes_from:
            - es-data-storage
        depends_on:
            - es-master

    es-data-storage:
        labels:
            io.rancher.container.start_once: true
        network_mode: none
        image: rawmind/alpine-volume:0.0.2-3
        environment:
            - SERVICE_UID=1000
            - SERVICE_GID=1000
            - SERVICE_VOLUME=/usr/share/elasticsearch/data
        volumes:
            - es-data-volume:/usr/share/elasticsearch/data

    es-client:
        labels:
            io.rancher.scheduler.affinity:container_label_soft_ne: io.rancher.stack_service.name=$${stack_name}/$${service_name}
            io.rancher.container.hostname_override: container_name
            io.rancher.sidekicks: es-client-storage{{- if eq .Values.UPDATE_SYSCTL "true" -}},es-client-sysctl{{- end}}
        image: docker.elastic.co/elasticsearch/elasticsearch:7.0.1
        environment:
            - "cluster.name=${cluster_name}"
            - "node.name=$${HOSTNAME}"
            - "bootstrap.memory_lock=true"
            - "discovery.seed_hosts=es-master"
            - "ES_JAVA_OPTS=-Xms${client_heap_size} -Xmx${client_heap_size}"
            - "node.master=false"
            - "node.data=false"
    {{- if eq .Values.EXPOSE_PORTS "true" }}
        ports:
            - "9200:9200"
            - "9300:9300"
    {{- end}}
        ulimits:
            memlock:
                soft: -1
                hard: -1
            nofile:
                soft: 65536
                hard: 65536
        mem_limit: ${client_mem_limit}
        mem_swappiness: 0
        cap_add:
            - IPC_LOCK
        # healthcheck:
        #     test: ['CMD', 'curl', '-f', 'http://localhost:9200']
        #     interval: 10s
        #     timeout: 5s
        #     retries: 3
        volumes_from:
            - es-client-storage
        depends_on:
            - es-master

    es-client-storage:
        labels:
            io.rancher.container.start_once: true
        network_mode: none
        image: rawmind/alpine-volume:0.0.2-3
        environment:
            - SERVICE_UID=1000
            - SERVICE_GID=1000
            - SERVICE_VOLUME=/usr/share/elasticsearch/data
        volumes:
            - es-client-volume:/usr/share/elasticsearch/data

    {{- if eq .Values.UPDATE_SYSCTL "true" }}
    es-master-sysctl:
        labels:
            io.rancher.container.start_once: true
        network_mode: none
        image: rawmind/alpine-sysctl:0.1-1
        privileged: true
        environment:
            - "SYSCTL_KEY=vm.max_map_count"
            - "SYSCTL_VALUE=262144"
    es-data-sysctl:
        labels:
            io.rancher.container.start_once: true
        network_mode: none
        image: rawmind/alpine-sysctl:0.1-1
        privileged: true
        environment:
            - "SYSCTL_KEY=vm.max_map_count"
            - "SYSCTL_VALUE=262144"
    es-client-sysctl:
        labels:
            io.rancher.container.start_once: true
        network_mode: none
        image: rawmind/alpine-sysctl:0.1-1
        privileged: true
        environment:
            - "SYSCTL_KEY=vm.max_map_count"
            - "SYSCTL_VALUE=262144"
    {{- end}}

volumes:
  es-master-volume:
    driver: ${VOLUME_DRIVER}
    per_container: true
  es-data-volume:
    driver: ${VOLUME_DRIVER}
    per_container: true
  es-client-volume:
    driver: ${VOLUME_DRIVER}
    per_container: true
