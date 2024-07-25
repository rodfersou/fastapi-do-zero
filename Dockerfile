# syntax=docker/dockerfile:1
FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive
ENV PATH="/nix/var/nix/profiles/default/bin:$PATH" \
    POETRY_CACHE_DIR="/cache/poetry"               \
    INSIDE_DOCKER="true"

COPY . /app
WORKDIR /app
EXPOSE 8000

RUN <<DOCKER_BEFORE   bash                                                          \
 && <<CONFIG_NIX_CONF sed -r 's/^ {4}//;/^$/d;/^#/d' | cat > ~/.config/nix/nix.conf \
 && <<DOCKER_AFTER    bash

# DOCKER BEFORE
    apt update -y
    apt install -y \
        curl
    mkdir -p ~/.config/nix
    mkdir -p /cache/poetry
DOCKER_BEFORE

# CONFIG NIX_CONF
    experimental-features = nix-command flakes
    filter-syscalls = false
CONFIG_NIX_CONF

# DOCKER AFTER
    # NIX
    curl --proto '=https'                           \
         --tlsv1.2                                  \
         -sSf                                       \
         -L https://install.determinate.systems/nix \
    | sh -s                                         \
         -- install linux                           \
         --extra-conf "sandbox = false"             \
         --extra-conf "filter-syscalls = false"     \
         --init none                                \
         --no-confirm

    # CLEAN
    nix-collect-garbage -d
    apt-get clean
    apt-get autoremove -y
    rm -rf /var/lib/apt/lists/*
DOCKER_AFTER
ENTRYPOINT ["nix", "develop", "--command"]
CMD ["/app/scripts/start"]
