FROM centos:7

ENV GOGS_VERSION="0.11.34"

LABEL name="Gogs - Go Git Service" \
      vendor="Gogs" \
      io.k8s.display-name="Gogs - Go Git Service" \
      io.k8s.description="The goal of this project is to make the easiest, fastest, and most painless way of setting up a self-hosted Git service." \
      io.openshift.expose-services="3000,gogs" \
      io.openshift.tags="gogs" \
      build-date="2017-11-29" \
      version=$GOGS_VERSION \
      release="1"

COPY scripts/* /opt/gogs/bin/
COPY contrib/zabbix_agentd.conf /opt/zabbix-agent/

# Install Prerequisites
# nss_wrapper is needed for matching the OpenShift
# assigned UserID to the `gogs` user when the container
# is running in OpenShift. See `/root/usr/bin/rungogs`
# shell script for how to use it.
RUN yum -y update && yum -y upgrade \
    && rpm -ivh http://repo.zabbix.com/zabbix/3.4/rhel/7/x86_64/zabbix-release-3.4-2.el7.noarch.rpm \
    && yum -y install epel-release \
    && yum -y install git nss_wrapper zabbix-agent \
    && yum -y clean all \
    && sed -i "s|@@HOME@@|/opt|g" /opt/zabbix-agent/zabbix_agentd.conf \
    && adduser gogs \
    && curl -L -o /tmp/gogs.tar.gz https://dl.gogs.io/$GOGS_VERSION/linux_amd64.tar.gz \
    && tar -xzf /tmp/gogs.tar.gz -C /opt \
    && rm /tmp/gogs.tar.gz \
    && mkdir /data \
    && chown -R gogs:gogs /data \
    && chown -R gogs:gogs /opt/gogs \
    && chmod -R g+rw /data \
    && chmod -R g+rw /opt/gogs \
    && chmod +x /opt/gogs/bin/fix-permissions \
    && chmod +x /opt/gogs/bin/rungogs \
    && chmod -R a+rwx /opt/zabbix-agent \
    && /opt/gogs/bin/fix-permissions /data \
    && /opt/gogs/bin/fix-permissions /opt/gogs

ENV HOME=/data
ENV USERNAME=gogs

VOLUME /data

EXPOSE 3000 10050
USER 997

CMD ["/opt/gogs/bin/rungogs"]
