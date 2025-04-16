# Use Ubuntu Jammy as the base image
FROM ubuntu:jammy

# Set non-interactive mode for package installation
ENV DEBIAN_FRONTEND=noninteractive

# Set the default shell
SHELL ["/bin/bash", "-c"]

# Install required system packages
RUN apt update && apt install -y \
    sudo \
    openjdk-17-jre-headless \
    openjdk-17-jdk-headless \
    linux-headers-$(uname -r) \
    p7zip-full \
    sysbench \
    lmbench \
    docker.io \
    docker-compose \
    cgroup-tools \
    python3-pip \
    python3 \
    ffmpeg \
    g++ \
    && apt clean

# FFMPEG and VMAF Packages. Need access to internal Netflix repository
# it may required bionic instead of jammy
# if jammy just remove bionic entry. Otherwise create a separate image
#FROM dockerregistry.test.netflix.net:7002/baseos/bionic:release
#RUN apt-get update
#RUN apt install -y build-essential
#RUN apt install -y et-ffmpeg-dev   # VMAF
#RUN apt install -y et-vie-ffmpeg-dev # ENCODE
#RUN apt-get install -y schedtool wget

# Create the /mnt directory and ensure proper permissions
RUN mkdir -p /mnt && chmod 777 /mnt

# Create the user 'bnetflix' and allow sudo without password
RUN useradd -m -s /bin/bash bnetflix && \
    echo "bnetflix ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Set up Java environment variables
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH="$JAVA_HOME/bin:$PATH"

# Set the working directory
WORKDIR /home/bnetflix

# Copy benchmark scripts and directories
COPY run-benchmarks-uProf run-benchmarks-perfspec run-benchmarks-noprofile benchmarks_environment.sh /home/bnetflix/
COPY benchmarks /home/bnetflix/benchmarks/
COPY binaries /home/bnetflix/binaries/

# Ensure scripts are executable
RUN chmod +x /home/bnetflix/run-benchmarks-uProf /home/bnetflix/run-benchmarks-perfspec /home/bnetflix/run-benchmarks-noprofile /home/bnetflix/benchmarks_environment.sh && \
    chmod -R +x /home/bnetflix/benchmarks && \
    chmod -R +x /home/bnetflix/binaries

RUN mkdir -p /efs && chown -R bnetflix:bnetflix /efs
# Set user to bnetflix
USER bnetflix

# Set the entrypoint to the benchmark script
ENTRYPOINT ["/home/bnetflix/run-benchmarks-noprofile"]
# NOTE : *** Please change Entrypoint script to run-benchmarks-uProf or run-benchmarks-noprofile if needed and then build again.

