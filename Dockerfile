ARG BUILD_JDK=8

FROM registry.access.redhat.com/ubi8/openjdk-8 as build_jdk8

FROM registry.access.redhat.com/ubi8/openjdk-11 as build_jdk11

FROM registry.access.redhat.com/ubi8/openjdk-17 as build_jdk17

FROM build_jdk${BUILD_JDK}
USER root
#update os and install tools
RUN microdnf update -y && microdnf install rsync git openssl skopeo jq procps -y

#add CA
RUN curl -s https://password.corp.redhat.com/RH-IT-Root-CA.crt > /etc/pki/ca-trust/source/anchors/RH-IT-Root-CA.crt \
	&& update-ca-trust

#import nexus SSL certificate to avoid validation issues
#RUN echo -n | openssl s_client -connect nexus.fuse-qe.eng.rdu2.redhat.com:443 -servername nexus.fuse-qe.eng.rdu2.redhat.com  | openssl x509 -trustout > /tmp/nexus.fuse-qe.eng.rdu2.redhat.com.pem
#RUN $JAVA_HOME/bin/keytool -importcert -alias nexus.fuse-qe.eng.rdu2.redhat.com -file /tmp/nexus.fuse-qe.eng.rdu2.redhat.com.pem -noprompt -keystore /etc/pki/ca-trust/extracted/java/cacerts -storepass changeit -trustcacerts \
#    && rm /tmp/nexus.fuse-qe.eng.rdu2.redhat.com.pem
#install maven
ADD https://archive.apache.org/dist/maven/maven-3/3.8.5/binaries/apache-maven-3.8.5-bin.tar.gz /tmp/
RUN mkdir /opt/maven \
    && tar -zxf /tmp/apache-maven-3.8.5-bin.tar.gz --directory /opt/maven \
    && mv /opt/maven/*/* /opt/maven/ \
    && rm -rf /opt/maven/apache-maven-3.8.5 \
    && rm /tmp/apache-maven-3.8.5-bin.tar.gz
#RUN sed -i 's|<blocked>true<\/blocked>|<blocked>false<\/blocked>|g' /opt/maven/conf/settings.xml  \
#    && sed -i 's|<url>http:\/\/0.0.0.0\/<\/url>|<url>http:\/\/repository.engineering.redhat.com\/nexus\/content\/repositories\/jboss-qa-releases\/<\/url>|g' /opt/maven/conf/settings.xml
RUN sed -i '159,165d' /opt/maven/conf/settings.xml

RUN mkdir -p /deployments && chown jboss:jboss /deployments
RUN mkdir -p /artifacts && chown jboss:jboss /artifacts
USER jboss
ARG GIT_BRANCH=master
ENV MVN_PROFILES=test-fuse,openshift4-current
ENV TEST_EXPR=
ENV NAMESPACE_NAME=
ENV NAMESPACE_PREFIX=user
ENV MVN_ARGS=-e
ENV MVN_SUREFIRE_ARGLINE=
ENV MVN_SETTINGS_PATH=/deployments/.m2/settings.xml
ENV SUREFIRE_REPORTS_FOLDER=/deployments/xpaas-qe/test-fuse/target/surefire-reports
ENV SUREFIRE_REPORTS_DEST_FOLDER=/tmp/surefire-reports
ENV LOG_DEST_FOLDER=/tmp/log
ENV SUREFIRE_REPORTS_DEST_FILES=*.xml
#set vars
ENV M2_HOME=/opt/maven
ENV PATH=$M2_HOME/bin:$PATH
#create custom mvn settings
ADD settings.xml /deployments/.m2/
#entrypoint script
ADD runMvn.sh /deployments/

RUN git config --global http.sslVerify false
#clone only the branch from args
RUN echo cloning branch $GIT_BRANCH
RUN git clone -b $GIT_BRANCH https://gitlab.cee.redhat.com/jboss-fuse-qe/xpaas-qe.git --depth=1 /deployments/xpaas-qe
#use the default property
RUN ln -s /mnt/test.properties /deployments/xpaas-qe/test.properties
USER root
RUN chmod +x /deployments/runMvn.sh
RUN chmod 777 -R /deployments/xpaas-qe
RUN chown jboss:jboss -R /home/jboss
RUN chmod 777 -R /home/jboss
# Clear package manager metadata
RUN microdnf clean all && [ ! -d /var/cache/yum ] || rm -rf /var/cache/yum
USER jboss
COPY artifacts/. /artifacts
WORKDIR /deployments/xpaas-qe
ENTRYPOINT ["/bin/bash", "/deployments/runMvn.sh"]
