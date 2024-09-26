# Use an official Ubuntu base image
FROM ubuntu:20.04

# Set environment variables
ENV NEXUS_VERSION=3.30.0-01
ENV NEXUS_DOWNLOAD_URL=https://download.sonatype.com/nexus/3/nexus-${NEXUS_VERSION}-unix.tar.gz
ENV SONATYPE_DIR=/opt/sonatype
ENV NEXUS_HOME=${SONATYPE_DIR}/nexus
ENV NEXUS_DATA=/nexus-data
ENV INSTALL4J_ADD_VM_PARAMS="-Xms2703m -Xmx2703m -XX:MaxDirectMemorySize=2703m"
ENV INSTALL4J_JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64

# Install required packages
RUN apt-get update && apt-get install -y \
#    openjdk-11-jdk \ 
    openjdk-8-jdk \
    openssl \ 
    libxml2 \
    gosu \
    curl \
    && apt-get clean

# Create necessary directories
RUN mkdir -p ${NEXUS_HOME} ${NEXUS_DATA} && \
    groupadd --gid 200 nexus && \
    useradd --uid 200 --gid nexus --shell /bin/false --create-home nexus

# Download and install Nexus
RUN curl -L ${NEXUS_DOWNLOAD_URL} -o nexus.tar.gz && \
    tar -xzf nexus.tar.gz -C ${SONATYPE_DIR} && \
    mv ${SONATYPE_DIR}/nexus-${NEXUS_VERSION} ${NEXUS_HOME} && \
    rm nexus.tar.gz && \
    chown -R nexus:nexus ${SONATYPE_DIR}
RUN echo 17


COPY ./entrypoint.sh /opt/sonatype/nexus/
# Expose the necessary ports
EXPOSE 8081
EXPOSE 8443
# Switch to the nexus user
USER nexus

# Set the working directory
WORKDIR ${NEXUS_HOME}

# Command to run Nexus
CMD ["bash", "entrypoint.sh"]
