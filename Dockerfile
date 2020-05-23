# Dockerfile for a Multi-Room-Audio-Streaming-Server

#FROM blitznote/debootstrap-amd64:16.04
FROM ubuntu:16.04

MAINTAINER s1lvester <hello@s1lvester.de>

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8

# get the stuffs
RUN apt-get -qq update &&\
    apt-get -qq install build-essential git avahi-daemon avahi-utils dbus shairport-sync \
        supervisor bzip2 portaudio19-dev libvorbisfile3 curl libprotoc-dev cargo &&\

# Snapcast, Shairport-sync,avahi and dbus
    curl -L -o /root/out.deb 'https://github.com/badaix/snapcast/releases/download/v0.15.0/snapserver_0.15.0_amd64.deb' &&\
    dpkg -i --force-all /root/out.deb &&\
    apt-get -y -f install &&\
    mkdir -p /root/.config/snapcast/ &&\
    rm -rf /var/run/* &&\
    mkdir -p /var/run/dbus &&\
    chown messagebus:messagebus /var/run/dbus &&\
    dbus-uuidgen --ensure &&\
    
# Snapcastr
    install_packages python3-dev \
    python3-pip \
    python3-virtualenv \
    python3-setuptools \
    git \
    gcc \
    libffi-dev \
    libssl-dev \
    python3-venv

RUN pip3 install wheel

RUN pip3 install Flask snapcast poetry

RUN cd /usr/src/ && \
    git clone https://github.com/xkonni/snapcastr && \
    cd snapcastr && \
    poetry build && \
    pip3 install dist/*.tar.gz

# cleanup
RUN apt-get -qq autoremove &&\
    apt-get -qq clean &&\
    rm /root/out.deb &&\
    rm -rf /var/lib/apt/lists/*

# mounting dbus on host so avahi can work.
VOLUME /var/run/dbus

# config-files
ADD ./supervisord.conf /etc/supervisord.conf
ADD ./shairport.cfg /etc/shairport.cfg
ADD ./asound.conf /etc/asound.conf
ADD ./start.sh /start.sh
ADD ./librespot /usr/local/bin/librespot
RUN chmod a+x /start.sh

# Snapcast Ports
EXPOSE 1704-1704

# AirPlay ports.
EXPOSE 3689/tcp
EXPOSE 5000-5005/tcp
EXPOSE 6000-6005/udp

# Avahi port
EXPOSE 5353

# Snapcastr port
EXPOSE 80/tcp

ENTRYPOINT ["/start.sh"]
