ARG JMETER_VERSION
FROM rbillon59/jmeter-k8s-base:${JMETER_VERSION}

## Installing java and dependencies
RUN  mkdir -p /opt/jmeter/apache-jmeter-${JMETER_VERSION}/results \
    && mkdir /opt/jmeter/apache-jmeter-${JMETER_VERSION}/logs/
ENTRYPOINT ["/opt/entrypoint.sh"]

COPY ./entrypoint.sh /opt/entrypoint.sh
ENV HOME /opt/jmeter/
