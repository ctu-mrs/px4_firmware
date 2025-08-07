# PX4 base development environment
FROM ctumrs/ros_jazzy
LABEL maintainer="Daniel Agar <daniel@agar.ca>, Ramon Roche <mrpollo@gmail.com>"

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV DISPLAY=:99
ENV TERM=xterm
ENV TZ=UTC
ENV RUNS_IN_DOCKER=true

# SITL UDP PORTS
EXPOSE 14556/udp
EXPOSE 14557/udp

# Install Shell Script Entrypoint
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

# Install PX4 Requirements
COPY requirements.txt /tmp/requirements.txt
COPY ubuntu.sh /tmp/ubuntu.sh

RUN bash /tmp/ubuntu.sh --no-sim-tools

# Make sure git is ok with your local copy
RUN git config --global --add safe.directory '*'

RUN curl https://ctu-mrs.github.io/ppa2-stable/add_ppa.sh | bash

RUN apt-get update && apt-get install -y \
    iputils-ping \
    vim \
    tmux \
    ranger \
    ros-jazzy-mavros \
    ros-jazzy-mrs-uav-px4-api \
    ros-jazzy-mrs-msgs \
    ros-jazzy-ros-gz \
    && rm -rf /var/lib/apt/lists/*

RUN gem install tmuxinator

RUN echo "source /opt/ros/jazzy/setup.bash" >> /root/.bashrc && \
    echo "source /opt/ros/jazzy/setup.bash" >> /etc/bash.bashrc

RUN echo "source /root/workspace/install/setup.bash" >> /root/.bashrc && \
    echo "source /root/workspace/install/setup.bash" >> /etc/bash.bashrc

# create user with id 1001 (jenkins docker workflow default)
RUN useradd --shell /bin/bash -u 1001 -c "" -m user && usermod -a -G dialout user

ENV PATH="${PATH}:/opt/xtensa-esp-elf/bin"

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

CMD ["/bin/bash"]
