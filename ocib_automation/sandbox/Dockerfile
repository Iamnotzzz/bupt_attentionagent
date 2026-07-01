FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    curl \
    git \
    jq \
    python3 \
    python3-pip \
    python3-venv \
    rsync \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -u 1000 agent
WORKDIR /workspace
USER agent

# Install OpenClaw or your OpenClaw wrapper here if you want the whole
# experiment to run inside the container. Otherwise use this image as a
# reference for a stricter production sandbox.
#
# Example placeholder:
# RUN pip3 install --user openclaw

CMD ["bash"]
