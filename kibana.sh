#!/bin/bash

# Copyright 2019 Amazon.com, Inc. or its affiliates. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License").
# You may not use this file except in compliance with the License.
# A copy of the License is located at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# or in the "license" file accompanying this file. This file is distributed
# on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
# express or implied. See the License for the specific language governing
# permissions and limitations under the License.

#
# Run Kibana, using environment variables to set longopts defining Kibana's
# configuration.
#
# eg. Setting the environment variable:
#
#       ELASTICSEARCH_STARTUPTIMEOUT=60
#
# will cause Kibana to be invoked with:
#
#       --elasticsearch.startupTimeout=60

kibana_vars=(
    console.enabled
    console.proxyConfig
    console.proxyFilter
    elasticsearch.customHeaders
    elasticsearch.logQueries
    elasticsearch.password
    elasticsearch.pingTimeout
    elasticsearch.preserveHost
    elasticsearch.requestHeadersWhitelist
    elasticsearch.requestTimeout
    elasticsearch.shardTimeout
    elasticsearch.ssl.ca
    elasticsearch.ssl.cert
    elasticsearch.ssl.certificate
    elasticsearch.ssl.certificateAuthorities
    elasticsearch.ssl.key
    elasticsearch.ssl.keyPassphrase
    elasticsearch.ssl.verificationMode
    elasticsearch.ssl.verify
    elasticsearch.startupTimeout
    elasticsearch.tribe.customHeaders
    elasticsearch.tribe.password
    elasticsearch.tribe.pingTimeout
    elasticsearch.tribe.requestHeadersWhitelist
    elasticsearch.tribe.requestTimeout
    elasticsearch.tribe.ssl.ca
    elasticsearch.tribe.ssl.cert
    elasticsearch.tribe.ssl.certificate
    elasticsearch.tribe.ssl.certificateAuthorities
    elasticsearch.tribe.ssl.key
    elasticsearch.tribe.ssl.keyPassphrase
    elasticsearch.tribe.ssl.verificationMode
    elasticsearch.tribe.ssl.verify
    elasticsearch.tribe.url
    elasticsearch.tribe.username
    elasticsearch.hosts
    elasticsearch.username
    kibana.defaultAppId
    kibana.index
    logging.dest
    logging.quiet
    logging.silent
    logging.useUTC
    logging.verbose
    map.includeElasticMapsService
    ops.interval
    path.data
    pid.file
    regionmap
    regionmap.includeElasticMapsService
    server.basePath
    server.customResponseHeaders
    server.defaultRoute
    server.host
    server.maxPayloadBytes
    server.name
    server.port
    server.rewriteBasePath
    server.ssl.cert
    server.ssl.certificate
    server.ssl.certificateAuthorities
    server.ssl.cipherSuites
    server.ssl.clientAuthentication
    server.customResponseHeaders
    server.ssl.enabled
    server.ssl.key
    server.ssl.keyPassphrase
    server.ssl.redirectHttpFromPort
    server.ssl.supportedProtocols
    server.xsrf.whitelist
    status.allowAnonymous
    status.v6ApiFormat
    tilemap.options.attribution
    tilemap.options.maxZoom
    tilemap.options.minZoom
    tilemap.options.subdomains
    tilemap.url
    timelion.enabled
    vega.enableExternalUrls
    opendistro_security.multitenancy.enabled
    opendistro_security.multitenancy.tenants.preferred
    opendistro_security.readonly_mode.roles
)

longopts=''
for kibana_var in ${kibana_vars[*]}; do
    # 'elasticsearch.hosts' -> 'ELASTICSEARCH_URL'
    env_var=$(echo ${kibana_var^^} | tr . _)

    # Indirectly lookup env var values via the name of the var.
    # REF: http://tldp.org/LDP/abs/html/bashver2.html#EX78
    value=${!env_var}
    if [[ -n $value ]]; then
      longopt="--${kibana_var}=${value}"
      longopts+=" ${longopt}"
    fi
done

# Files created at run-time should be group-writable, for Openshift's sake.
umask 0002

# TO DO:
# Confirm with Mihir if this is necessary

# The virtual file /proc/self/cgroup should list the current cgroup
# membership. For each hierarchy, you can follow the cgroup path from
# this file to the cgroup filesystem (usually /sys/fs/cgroup/) and
# introspect the statistics for the cgroup for the given
# hierarchy. Alas, Docker breaks this by mounting the container
# statistics at the root while leaving the cgroup paths as the actual
# paths. Therefore, Kibana provides a mechanism to override
# reading the cgroup path from /proc/self/cgroup and instead uses the
# cgroup path defined the configuration properties
# cpu.cgroup.path.override and cpuacct.cgroup.path.override.
# Therefore, we set this value here so that cgroup statistics are
# available for the container this process will run in.

exec /usr/share/kibana/bin/kibana --cpu.cgroup.path.override=/ --cpuacct.cgroup.path.override=/ ${longopts} "$@"
