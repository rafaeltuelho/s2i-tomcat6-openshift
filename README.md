# Apache Tomcat 6 Build Image

This image was created as part of a Proof of Concept to host a legacy web app based on Apache Tomcat 6 web server. It's based on the official __JBoss Web Server 3.1 - Tomcat 7__ image [1]. To understand how Openshift builder images works please refer to the Source to Image project's page at https://github.com/openshift/source-to-image

## To build this image:

```
docker build --rm -t rafaeltuelho/s2i-tomcat6-centos7 \
 --build-arg TOMCAT_MAJOR=6 \
 --build-arg TOMCAT_VERSION=6.0.53
```

The `Dockerfile` use the Apache Tomcat's archive binary repository (https://archive.apache.org/dist/tomcat) to download the binary tgz.

## To build your Tomcat 6 Web App using this image you just need to follow these steps:

* download `s2i` binary from https://github.com/openshift/source-to-image/releases
* build your image using **s2i**
 * usando source repository
  
```
$ s2i build <your git repo url> rafaeltuelho/s2i-tomcat6-centos7 mytomcat6-app
$ docker run --rm -i -p :8080 -t mytomcat6-app
```

 * usando binary deployment no openshift

```
$ mkdir -p binary-deploy/deployments && cd binary-deploy/
$ cp myapp.war deployments/

```
___
[1] https://access.redhat.com/containers/?tab=overview#/registry.access.redhat.com/jboss-webserver-3/webserver31-tomcat7-openshift
