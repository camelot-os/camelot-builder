# syntax=docker/dockerfile:1

# ============================================================
# Stage 1 — Rust builder (contains build dependencies)
# ============================================================
FROM debian:13-slim AS rust-builder

ENV DEBIAN_FRONTEND=noninteractive
ENV RUSTUP_HOME=/opt/rust
ENV CARGO_HOME=/opt/rust/cargo
ENV PATH=/opt/rust/cargo/bin:$PATH
ENV RUST_VERSION=1.86.0

RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    git \
    ca-certificates \
    pkg-config \
    cmake \
    ninja-build \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Rust 1.86.0 (minimal profile)
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y \
    --default-toolchain ${RUST_VERSION} \
    --profile minimal \
    && rustup default nightly \
    && rustup target add thumbv8m.main-none-eabi \
    && rustup show

# Install Clippy and Rustfmt
RUN rustup component add clippy --toolchain ${RUST_VERSION} \
    && rustup component add rustfmt --toolchain ${RUST_VERSION}

# Install cargo-index
RUN cargo +${RUST_VERSION} install cargo-index

# ============================================================
# Stage 2 — Clean toolchain image (NO Rust build deps)
# ============================================================
FROM debian:13-slim AS toolchain

ENV DEBIAN_FRONTEND=noninteractive
ENV RUSTUP_HOME=/opt/rust
ENV ARM_TOOLCHAIN_VERSION=15.2.rel1
ENV ARM_INSTALL_DIR=/opt/arm/arm-none-eabi
ENV PATH=${ARM_INSTALL_DIR}/bin:/opt/rust/cargo/bin:$PATH

RUN apt-get update && apt-get install -y \
    git \
    ca-certificates \
    python3 \
    python3-pip \
    python3-venv \
    python3-setuptools \
    python3-wheel \
    device-tree-compiler \
    g++ \
    gcc \
    curl \
    dirmngr \
    xz-utils \
    pkg-config \
    srecord \
    && rm -rf /var/lib/apt/lists/*

# Python dependencies required by sentry-kernel
RUN python3 -m pip install --break-system-packages --no-cache-dir \
    meson==1.10.0 \
    dunamai \
    camelot-barbican

# ------------------------------------------------------------
# Install Arm GNU Toolchain 15.2.rel1 with signature check
# ------------------------------------------------------------
WORKDIR /tmp

ENV ARM_BASE_URL=https://developer.arm.com/-/media/Files/downloads/gnu/${ARM_TOOLCHAIN_VERSION}/binrel
ENV ARM_ARCHIVE=arm-gnu-toolchain-${ARM_TOOLCHAIN_VERSION}-x86_64-arm-none-eabi.tar.xz

RUN curl -LO ${ARM_BASE_URL}/${ARM_ARCHIVE} \
    && curl -LO ${ARM_BASE_URL}/${ARM_ARCHIVE}.sha256asc

# Verify SHA256 checksum
RUN grep -oE '^[a-f0-9]{64}' ${ARM_ARCHIVE}.sha256asc > expected.sha256 \
    && echo "$(cat expected.sha256)  ${ARM_ARCHIVE}" > checksum.txt \
    && sha256sum -c checksum.txt

# Extract toolchain
RUN mkdir -p ${ARM_INSTALL_DIR} \
    && tar -xf ${ARM_ARCHIVE} \
    && mv arm-gnu-toolchain-${ARM_TOOLCHAIN_VERSION}-x86_64-arm-none-eabi/* ${ARM_INSTALL_DIR} \
    && rm -rf /tmp/*

# Copy prebuilt Rust toolchain
COPY --from=rust-builder /opt/rust /opt/rust

# Minimal global Git configuration
RUN git config --system user.name "Camelot Builder" \
    && git config --system user.email "builder@camelot.local"

# ============================================================
# Stage 3 — Validation (executed during docker build)
# ============================================================
FROM toolchain AS validation

WORKDIR /tmp

# Clone sample-project at fixed revision for hermetic build
ARG SAMPLE_PROJECT_REF=main
RUN git clone https://github.com/camelot-os/sample-project.git \
    && cd sample-project \
    && git checkout ${SAMPLE_PROJECT_REF}

WORKDIR /tmp/sample-project

# Validation build (FAILS docker build if error)
RUN barbican download && barbican setup
RUN ninja -C output/build || true
RUN ninja -C output/build

# ============================================================
# Stage 4 — Final minimal image
# ============================================================
FROM toolchain AS final

CMD ["bash"]

