FROM jenkins/jnlp-slave:latest

USER root
RUN echo "${TIMEZONE}" > /etc/timezone \
    && echo "$LANG UTF-8" > /etc/locale.gen \
    && apt-get update -q \
    && ln -sf /usr/share/zoneinfo/${TIMEZONE} /etc/localtime

COPY kubectl /usr/bin/kubectl
COPY docker /usr/bin/docker


## Install Maven
ARG USER_HOME_DIR="/root"
#


RUN mkdir -p /usr/share/maven /usr/share/maven/ref \
&& curl -fsSL -o /tmp/apache-maven.tar.gz https://apache.osuosl.org/maven/maven-3/3.5.4/binaries/apache-maven-3.5.4-bin.tar.gz \
&& tar -xzf /tmp/apache-maven.tar.gz -C /usr/share/maven --strip-components=1 \
&& rm -f /tmp/apache-maven.tar.gz \
&& ln -s /usr/share/maven/bin/mvn /usr/bin/mvn \
&& DEBIAN_FRONTEND=noninteractive apt-get install -yq curl apt-utils dialog locales  apt-transport-https build-essential bzip2 ca-certificates  sudo jq unzip zip gnupg2 software-properties-common \
&& update-locale LANG=$LANG \
&& locale-gen $LANG \
&& DEBIAN_FRONTEND=noninteractive dpkg-reconfigure locales \
&&curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg |apt-key add - \
&& add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") $(lsb_release -cs) stable" \
&& apt-get update -y \
&& apt-get install -y docker-ce git openssl \
&& rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
&& usermod -a -G docker jenkins \
&& sed -i '/^root/a\jenkins    ALL=(ALL:ALL) NOPASSWD:ALL' /etc/sudoers

ENV MAVEN_HOME /usr/share/maven
ENV MAVEN_CONFIG "$USER_HOME_DIR/.m2"

WORKDIR /home/jenkins
ENTRYPOINT ["jenkins-slave"]
