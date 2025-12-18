FROM ubuntu:noble

ARG TARGETARCH

# Install curl
RUN apt update && \
    DEBIAN_FRONTEND=noninteractive apt install curl fuse binutils jq conntrack iptables strace apt-transport-https iproute2 ca-certificates gpg systemd systemd-sysv dbus cloud-init kmod -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Change workdir
WORKDIR /home

# copy in the systemd unit
COPY files /

# Delete ubuntu user
RUN deluser ubuntu

# Let Docker know how to stop the container
STOPSIGNAL SIGRTMIN+3

# Tell systemd we’re in a container
ENV container=docker

# Launch systemd as PID 1
CMD ["/entrypoint.sh"]
