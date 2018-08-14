# s2i-tomcat6-openshift
FROM centos/s2i-base-centos7

MAINTAINER Rafael T. C. Soares <rsoares@redhat.com>

ARG TOMCAT_MAJOR=6
ARG TOMCAT_VERSION=6.0.53
ARG TOMCAT_TGZ_URL="https://archive.apache.org/dist/tomcat/tomcat-$TOMCAT_MAJOR/v$TOMCAT_VERSION/bin/apache-tomcat-$TOMCAT_VERSION.tar.gz"

ENV BUILDER_VERSION 1.0
ENV TOMCAT_IMAGE_NAME rafaeltuelho/s2i-tomcat6-centos7
ENV CATALINA_HOME "/opt/webserver"

LABEL io.k8s.description="Platform for building Tomcat 6 (JavaSE 7) based webapps" \
      io.k8s.display-name="Tomcat 6.0.53 (JavaSE 7) builder" \
      io.openshift.expose-services="8080:http" \
      io.openshift.tags="builder,tomcat,jee,java7" \
      io.openshift.s2i.scripts-url="image:///usr/local/s2i" \
      Architecture="x86_64" \
      Name="tomcat6-openshift" \
      Release="1" \
      Version="1.0" \
      com.redhat.deployments-dir="/opt/webserver/webapps" \
      com.redhat.dev-mode="DEBUG:true" \
      com.redhat.dev-mode.port="JPDA_ADDRESS:8000"

# Install required packages here:
# Install build tools on top of base image
# Java jdk 8, Maven 3.3, Gradle 2.6
RUN INSTALL_PKGS="unzip java-1.7.0-openjdk java-1.7.0-openjdk-devel" && \
    yum update -y && yum install -y --enablerepo=centosplus $INSTALL_PKGS && \
    rpm -V $INSTALL_PKGS && \
    yum clean all -y

# Download and install Apache Maven
ENV MAVEN_VERSION 3.3.9
RUN (curl -0 http://www.eu.apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz | \
    tar -zx -C /usr/local) && \
    mv /usr/local/apache-maven-$MAVEN_VERSION /usr/local/maven && \
    ln -sf /usr/local/maven/bin/mvn /usr/local/bin/mvn

ENV PATH=/opt/maven/bin/:$PATH

# COPY Additional files,configurations that we want to ship by default, like a default setting.xml
COPY ./.contrib/settings.xml $HOME/.m2/

# Download a specif version of Apache Tomcat from Apache's offcial website
RUN echo "downloading Apache Tomcat Web Server version $TOMCAT_VERSION" && \
 wget -O /tmp/tomcat.tar.gz "$TOMCAT_TGZ_URL"

# extract tomcat bin content
RUN mkdir $CATALINA_HOME && \
 tar -xvf /tmp/tomcat.tar.gz --strip-components=1 -C $CATALINA_HOME/

# remove tomcat default ROOT app
RUN mv $CATALINA_HOME/webapps/ROOT /tmp; rm $CATALINA_HOME/bin/*.bat

COPY ./.contrib/jolokia.jar $CATALINA_HOME/lib
# copy a custom tomcat startup script
COPY ./.contrib/launch.sh $CATALINA_HOME/bin
# copy an utility script used by lauch in order to get continer runtime resource info
RUN mkdir /usr/local/dynamic-resources
COPY ./.contrib/dynamic_resources.sh /usr/local/dynamic-resources/

RUN rm /tmp/tomcat.tar.gz

# Copy the S2I scripts to /usr/libexec/s2i, since openshift/base-centos7 image sets io.openshift.s2i.scripts-url label that way, or update that label
COPY ./.s2i/bin/ /usr/local/s2i

RUN chown -R 1001:1001 $HOME $CATALINA_HOME

# ensure the Arbitrary User used by openshift will be able to execute the process.
# see "Support Arbitrary User IDs" on https://docs.openshift.com/container-platform/3.4/creating_images/guidelines.html#openshift-container-platform-specific-guidelines
RUN chgrp -R 0 $HOME $CATALINA_HOME && \
 chmod -R g+rwX $HOME $CATALINA_HOME && \
 find $CATALINA_HOME -type d -exec chmod g+x {} +

# This default user is created in the openshift/base-centos7 image
USER 1001

EXPOSE 8080 8009 8443 8778

CMD ["/usr/local/s2i/usage"]
