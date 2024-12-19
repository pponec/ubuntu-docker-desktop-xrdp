# Build xrdp from UBUNTU 24.04 LTS
# See functions of the file: init.sh

ARG TAG=noble
FROM ubuntu:$TAG

ENV DEBIAN_FRONTEND noninteractive
ENV DISPLAY ${DISPLAY:-:1}

RUN <<-EOF
    apt-get update
    apt-get -y upgrade
    apt-get -y install --no-install-recommends -o APT::Immediate-Configure=0 \
        ca-certificates \
        dbus-x11 \
        locales \
        mesa-utils \
        mesa-utils-extra \
        openssh-server \
        openssl \
        x11-utils \
        x11-xserver-utils \
        xauth \
        xdg-utils \
        xfce4 \
        xfce4-goodies \
        xorgxrdp \
        xrdp \
        xubuntu-icon-theme

	apt-get -y install --no-install-recommends -o APT::Immediate-Configure=0 \
        apt-utils \
        chpasswd \
        curl \
        git \
        gnupg \
        lsb-release \
        psmisc \
        vim \
        wget

    apt-get clean
    rm -rf /var/lib/apt/lists/*
EOF

# Firefox (snap fails)
#RUN <<-EOF
#    apt update
#    install -d -m 0755 /etc/apt/keyrings
#    wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | tee /etc/apt/keyrings/packages.mozilla.org.asc > /dev/null
#    echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" | tee -a /etc/apt/sources.list.d/mozilla.list > /dev/null
#    echo "Package: *\nPin: origin packages.mozilla.org\nPin-Priority: 1000" | tee /etc/apt/preferences.d/mozilla
#    apt-get -y install firefox && apt clean
#EOF

# Create a new user and add to the sudo group:
ENV USERNAME=demo
ARG PASSWORD=changeit
RUN useradd -ms /bin/bash --home-dir /home/${USERNAME} ${USERNAME} && echo "${USERNAME}:${PASSWORD}" | chpasswd
RUN usermod -aG sudo,xrdp ${USERNAME}
COPY xfce-config/.config /home/xfce-config/.config

# Create a start script:
ENV entry=/usr/bin/entrypoint
RUN cat <<EOF > /usr/bin/entrypoint
#!/bin/bash -v
  cd /home/${USERNAME}
  DEFAULT_CONFIG_FILE=.config/.default_user_config
  test ! -d "\$DEFAULT_CONFIG_FILE" && {
    cp -r /home/xfce-config/.config .
    chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}
    mkdir -p "\$DEFAULT_CONFIG_FILE"
  }
  service dbus start
  service xrdp start
  tail -f /dev/null
EOF
RUN chmod +x /usr/bin/entrypoint

RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
EXPOSE 3389/tcp
ENTRYPOINT ["/usr/bin/entrypoint"]