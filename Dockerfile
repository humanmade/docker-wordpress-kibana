FROM amazon/opendistro-for-elasticsearch-kibana:1.11.0
RUN bin/kibana-plugin remove --silent opendistro_security
