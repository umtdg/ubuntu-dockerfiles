FROM ubuntu:xenial

ENV DEBIAN_FRONTEND noninteractive

# Install sudo
RUN apt-get update && apt-get install -y sudo

# Add non-root user
RUN addgroup --gid 1000 devuser
RUN adduser --gecos "" --uid 1000 --gid 1000 devuser
RUN echo 'devuser:devuser' | chpasswd

# Add user HOME and USER environment variables
ENV HOME /home/devuser
ENV USER devuser

# Add user to sudoers
RUN echo "$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Switch to non-root user
WORKDIR "$HOME"
USER devuser
