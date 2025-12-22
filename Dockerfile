FROM debian:bookworm-slim

ARG ZEPHYR_SDK_VERSION=0.16.8
ARG CMAKE_VERSION=3.28.1
ARG WEST_VERSION=1.2.0
ARG TARGETARCH

ENV DEBIAN_FRONTEND=noninteractive
ENV ZEPHYR_SDK_INSTALL_DIR=/opt/zephyr-sdk
ENV PATH="/root/.local/bin:${PATH}"

# Install base dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    wget \
    curl \
    xz-utils \
    file \
    make \
    gcc \
    g++ \
    libsdl2-dev \
    libmagic1 \
    python3 \
    python3-pip \
    python3-venv \
    python3-setuptools \
    python3-wheel \
    ninja-build \
    ccache \
    dfu-util \
    device-tree-compiler \
    protobuf-compiler \
    && rm -rf /var/lib/apt/lists/*

# Install CMake (architecture-aware)
RUN if [ "$TARGETARCH" = "arm64" ]; then \
        CMAKE_ARCH="linux-aarch64"; \
    else \
        CMAKE_ARCH="linux-x86_64"; \
    fi && \
    wget -q https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-${CMAKE_ARCH}.sh \
    && chmod +x cmake-${CMAKE_VERSION}-${CMAKE_ARCH}.sh \
    && ./cmake-${CMAKE_VERSION}-${CMAKE_ARCH}.sh --skip-license --prefix=/usr/local \
    && rm cmake-${CMAKE_VERSION}-${CMAKE_ARCH}.sh

# Install West and Python dependencies
RUN pip3 install --break-system-packages --user \
    west==${WEST_VERSION} \
    pyelftools \
    pyyaml \
    pykwalify \
    canopen \
    packaging \
    progress \
    psutil \
    anytree \
    intelhex \
    protobuf \
    grpcio-tools

# Install Zephyr SDK (minimal - just ARM toolchain for nRF52840)
RUN if [ "$TARGETARCH" = "arm64" ]; then \
        HOST_ARCH="linux-aarch64"; \
    else \
        HOST_ARCH="linux-x86_64"; \
    fi && \
    wget -q https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${ZEPHYR_SDK_VERSION}/zephyr-sdk-${ZEPHYR_SDK_VERSION}_${HOST_ARCH}_minimal.tar.xz \
    && tar -xf zephyr-sdk-${ZEPHYR_SDK_VERSION}_${HOST_ARCH}_minimal.tar.xz -C /opt \
    && rm zephyr-sdk-${ZEPHYR_SDK_VERSION}_${HOST_ARCH}_minimal.tar.xz \
    && mv /opt/zephyr-sdk-${ZEPHYR_SDK_VERSION} ${ZEPHYR_SDK_INSTALL_DIR} \
    && cd ${ZEPHYR_SDK_INSTALL_DIR} \
    && ./setup.sh -h -c \
    && wget -q https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${ZEPHYR_SDK_VERSION}/toolchain_${HOST_ARCH}_arm-zephyr-eabi.tar.xz \
    && tar -xf toolchain_${HOST_ARCH}_arm-zephyr-eabi.tar.xz \
    && rm toolchain_${HOST_ARCH}_arm-zephyr-eabi.tar.xz

# Set up workspace directory
WORKDIR /workspace

# Copy entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# The zmk-config repo will be mounted at /workspace at runtime
VOLUME /workspace

# Default command runs build
CMD ["docker-entrypoint.sh"]
