## note

Maven downloaded from https://archive.apache.org/dist/maven/maven-3/3.8.5/binaries/apache-maven-3.8.5-bin.tar.gz

### env credentials to inject into container
All the following credential needs to be filled as environment variables into the container during the run execution used into the settings.xml file, otherwise it is possible to mount a specific settings.xml using the variable MVN_SETTINGS_PATH.

ex:
podman .... -v /path/to/local/settings.xml:/root/custom.settings.xml:ro -e  MVN_SETTINGS_PATH=/root/custom.settings.xml....

#### credential for fabric8.upload.repo
- F8_USER
- F8_PWD

#### credential TomcatServer
- TOMCAT_USER
- TOMCAT_PWD

#### credential for nexus
- NEXUS_USER
- NEXUS_PWD

#### credential for fabric8.console
- F8_CONSOLE_USER
- F8_CONSOLE_PWD

#### credential for jboss-releases-repository
- JBOSS_USER
- JBOSS_PWD

## build

podman build --no-cache --build-arg BUILD_JDK=[8,11,17] --build-arg GIT_BRANCH=[git branch] -t xpaas-qe:[tag] .

- BUILD_JDK=[8,11,17]
- GIT_BRANCH=[name of the git branch]

ex:

podman build --no-cache --build-arg BUILD_JDK=17 --build-arg GIT_BRANCH=master -t xpaas-qe:jdk17 .

it generates image:
localhost/xpaas-qe:jdk17

## run

podman run --rm --privileged --userns host -v [path to local test.properties]:/mnt/test.properties:ro -v ~/.m2/repository:/deployments/.m2/repository:Z -e MVN_PROFILES=[mvn profiles] -e TEST_EXPR=[test to run] -e NAMESPACE_PREFIX=[project prefix] [name:tag of the built image]

- MVN_PROFILES=[list of the mvn profiles]
- TEST_EXPR=[expression for test execution (ex: name)]
- NAMESPACE_PREFIX=[prefix for namespace, will be concatenated to random suffix]
- MVN_ARGS=[maven args, -B is already there]

ex:

podman run --rm --privileged --userns host -e MVN_SETTINGS_PATH=/deployments/custom.settings.xml -v ~/.m2/settings.xml:/deployments/custom.settings.xml:ro -v ~/jboss-fuse-qe/xpaas-qe/test.properties:/mnt/test.properties:ro -v ~/.m2/repository:/deployments/.m2/repository:Z -e MVN_PROFILES=test-fuse,openshift4-current -e TEST_EXPR=KarafCxfJaxWsCatalogTest -e NAMESPACE_PREFIX=mcarlett localhost/xpaas-qe:jdk8
