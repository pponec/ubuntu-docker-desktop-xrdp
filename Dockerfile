# Build xrdp from UBUNTU 24.04 LTS
# See functions of the file: init.sh

ARG TAG=noble
FROM ubuntu:$TAG

ENV DEBIAN_FRONTEND noninteractive
ENV DISPLAY ${DISPLAY:-:1}

RUN apt update \
 && apt -y upgrade \
 && apt -y install --no-install-recommends -o APT::Immediate-Configure=0 \
        ca-certificates \
        dbus-x11 \
        locales \
        x11-utils \
        x11-xserver-utils \
        xauth \
        xdg-utils \
        xfce4 \
        xfce4-goodies \
        xorgxrdp \
        xrdp \
        xubuntu-icon-theme \
 && apt clean


# Utilities
RUN apt -y install --no-install-recommends -o APT::Immediate-Configure=0 \
        apt-utils \
        curl \
        git \
        gnupg \
        lsb-release \
        psmisc \
        vim \
        wget \
 && apt clean

## Firefox (snap fails)
RUN printf "Package: firefox*\nPin: release o=Ubuntu*\nPin-Priority: -1" > /etc/apt/preferences.d/firefox-no-snap \
 && install -d -m 0755 /etc/apt/keyrings \
 && wget -q https://packages.mozilla.org/apt/repo-signing-key.gpg -O- | tee /etc/apt/keyrings/packages.mozilla.org.asc > /dev/null \
 && echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" | tee -a /etc/apt/sources.list.d/mozilla.list > /dev/null \
 && echo "Package: *\nPin: origin packages.mozilla.org\nPin-Priority: 1000" | tee /etc/apt/preferences.d/mozilla \
 && apt update \
 && apt -y install firefox \
 && apt clean

# Create a new user and add to the sudo group:
ENV USERNAME=demo
ARG PASSWORD=changeit
RUN useradd -ms /bin/bash --home-dir /home/${USERNAME} ${USERNAME} && echo "${USERNAME}:${PASSWORD}" | chpasswd \
 && usermod -aG sudo,xrdp ${USERNAME} \
 && locale-gen en_US.UTF-8
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

ENV LANG=en_US.UTF-8
EXPOSE 3389/tcp
ENTRYPOINT ["/usr/bin/entrypoint"]