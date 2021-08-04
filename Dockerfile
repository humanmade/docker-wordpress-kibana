# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
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

# This dockerfile generates an AmazonLinux-based image containing an OpenDistro for Elasticsearch (ODFE) installation.
# It assumes that the working directory contains four files: an ODFE tarball (odfe.tgz), log4j2.properties, elasticsearch.yml, docker-entrypoint.sh.
# Build arguments:
#   ODFE_VERSION: Required. Used to label the image.
#   BUILD_DATE: Required. Used to label the image. Should be in the form 'yyyy-mm-ddThh:mm:ssZ', i.e. a date-time from https://tools.ietf.org/html/rfc3339. The timestamp must be in UTC.
#   UID: Optional. Specify the elasticsearch userid. Defaults to 1000.
#   GID: Optional. Specify the elasticsearch groupid. Defaults to 1000.

FROM amazonlinux:2 AS build

# Install the tools we need: tar and gzip to unpack the ODFE tarball, and shadow-utils to give us `groupadd` and `useradd`.
RUN yum install -y tar gzip shadow-utils curl

ARG TARGETARCH

ARG UID=1000
ARG GID=1000

# Create an elasticsearch user, group, and directory
RUN groupadd -g $GID kibana && \
    adduser -u $UID -g $GID -d /usr/share/kibana kibana

RUN mkdir /tmp/kibana

ARG ODFE_VERSION=1.13.2
RUN [[ "${TARGETARCH}" == "amd64" ]] && export ARCH=x64 || export ARCH=arm64 && curl https://d3g5vo6xdbdb9a.cloudfront.net/tarball/opendistroforelasticsearch-kibana/opendistroforelasticsearch-kibana-${ODFE_VERSION}-linux-$ARCH.tar.gz -o /tmp/kibana/odfe.tgz \
    && tar -xzf /tmp/kibana/odfe.tgz -C /usr/share/kibana --strip-components=1 \
    && chown -R $UID:$GID /usr/share/kibana \
    && echo $'= CentOS Licensing and Source Code =\n\nThis image is built from CentOS and DockerHub\'s official build of CentOS (https://hub.docker.com/_/centos). Their image contains various Open Source licensed packages and their DockerHub home page provides information on licensing.\n\nYou can list the packages installed in the image by running \'rpm -qa\', and you can download the source code for the packages CentOS and DockerHub provide via the yumdownloader tool.' > /root/CENTOS_LICENSING.txt \
    && rm -rf /tmp/kibana

COPY kibana.yml /usr/share/kibana/config/kibana.yml
COPY --chown=1000:0 kibana.sh /usr/local/bin/kibana-docker
RUN chmod +x /usr/local/bin/kibana-docker

# Set up the entry point, working directory, exposed ports etc
USER $UID

RUN /usr/share/kibana/bin/kibana-plugin remove opendistroSecurityKibana

WORKDIR /usr/share/kibana

EXPOSE 5601

CMD ["/usr/local/bin/kibana-docker"]

# Label
ARG ODFE_VERSION
ARG BUILD_DATE

LABEL org.label-schema.schema-version="1.0" \
  org.label-schema.name="opendistroforelasticsearch-kibana" \
  org.label-schema.version="$ODFE_VERSION" \
  org.label-schema.url="https://opendistro.github.io" \
  org.label-schema.vcs-url="https://github.com/opendistro-for-elasticsearch/opendistro-build" \
  org.label-schema.license="Apache-2.0" \
  org.label-schema.vendor="Amazon" \
  org.label-schema.build-date="$BUILD_DATE"
