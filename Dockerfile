FROM ubuntu:24.04

RUN apt update && apt install -y sudo zsh

# Give ubuntu user sudo privileges (ubuntu user already exists in the base image)
RUN echo 'ubuntu ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Set zsh as the default shell for ubuntu user
RUN chsh -s /bin/zsh ubuntu