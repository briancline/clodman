FROM fedora:43

ARG BUILD_DATE
ARG IMAGE_VER
# ARG GIT_REF
ARG CLAUDE_UID
ARG CLAUDE_GID

LABEL \
    org.opencontainers.image.created="${BUILD_DATE}" \
    org.opencontainers.image.title="claudecode" \
    org.opencontainers.image.version="${IMAGE_VER}" \
    org.opencontainers.image.vendor="Brian Cline" \
    org.opencontainers.image.authors="brian.cline@gmail.com" \
    org.opencontainers.image.source="https://github.com/briancline/clodman" \
    org.opencontainers.image.url="https://github.com/briancline/clodman" \
    org.opencontainers.image.licenses="MIT" \
    org.opencontainers.image.description="Claude Code in a Fedora container"
    # org.opencontainers.image.revision="${GIT_REF}"

RUN sed -r -e 's|^tsflags=(.*)[\s,]*nodocs\s*,?(\s*.*)$|tsflags=\1\2|' -i /etc/dnf/dnf.conf
COPY kubernetes.repo /etc/yum.repos.d/
COPY tools.txt /
# --nodocs
RUN dnf upgrade -y --refresh && \
    dnf reinstall -y coreutils shadow-utils && \
    dnf install -y --setopt=install_weak_deps=False \
        which procps-ng less fd-find tree \
        tar gzip zip unzip \
        man-db \
        curl rsync bind-utils mtr \
        ripgrep \
        vim-enhanced git jq yq \
        skopeo \
        shellcheck \
        hadolint \
        ansible ansible-builder \
        ansible-lint yamllint \
        python3.11 \
        python3.12 \
        python3-pylint python3-flake8* python3-mypy \
        python3-pip \
        python3-pyyaml \
        python3-requests \
        uv \
        shellcheck \
        golang \
        kubectl kustomize helm \
        age \
    && \
    dnf group install -y development-tools && \
    dnf list --installed > /packages.txt && \
    dnf clean all && \
    rm -rf /var/cache/dnf

RUN \
    CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt) \
    && GOOS=linux GOARCH=amd64 \
    && curl -fsSL "https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-${GOOS}-${GOARCH}.tar.gz" \
        | tar -xzv -C /usr/local/bin \
    \
    && KUBECONFORM_VERSION=$(curl -fsSL https://api.github.com/repos/yannh/kubeconform/releases/latest | jq -r .tag_name | sed 's/^v//') \
    && curl -fsSL "https://github.com/yannh/kubeconform/releases/download/v${KUBECONFORM_VERSION}/kubeconform-linux-amd64.tar.gz" \
        | tar -xz -C /usr/local/bin kubeconform \
    \
    && SOPS_VERSION=$(curl -fsSL https://api.github.com/repos/getsops/sops/releases/latest | jq -r .tag_name | sed 's/^v//') \
    && curl -fsSL "https://github.com/getsops/sops/releases/download/v${SOPS_VERSION}/sops-v${SOPS_VERSION}.linux.amd64" \
        -o /usr/local/bin/sops \
    \
    && STERN_VERSION=$(curl -fsSL https://api.github.com/repos/stern/stern/releases/latest | jq -r .tag_name | sed 's/^v//') \
    && curl -fsSL "https://github.com/stern/stern/releases/download/v${STERN_VERSION}/stern_${STERN_VERSION}_linux_amd64.tar.gz" \
        | tar -xz -C /usr/local/bin stern \
    \
    && chmod +x /usr/local/bin/{cilium,kubeconform,sops,stern} \
    \
    && uv tool install check-jsonschema

RUN groupadd --gid "${CLAUDE_GID}" claude && \
    useradd --uid "${CLAUDE_UID}" --gid "${CLAUDE_GID}" --create-home --home-dir /home/claude claude



USER claude
RUN set -o pipefail && \
    curl -LsSf https://claude.ai/install.sh | bash && \
    rm -rf ~/.claude ~/.claude.json

WORKDIR /code
ENV PATH="/home/claude/.local/bin:${PATH}"
ENV DISABLE_AUTOUPDATER=1
CMD ["/home/claude/.local/bin/claude"]
