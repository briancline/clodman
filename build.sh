#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

# Technically the image should be inspected after build to get the installed claude-code version, but
# this is close enough. Used for tagging the image and giving it a version in its LABEL directives.
claude_code_ver="$(curl -s "https://registry.npmjs.org/@anthropic-ai/claude-code/latest" | jq -r .version)"
build_ts="$(date +%s)"
build_date="$(date +%Y-%m-%dT%H:%M:%S%z -d @${build_ts})"
tag_date="$(date +%Y%m%d.%H%M%S -d @${build_ts})"
image_ver="${claude_code_ver}.${tag_date}"
kube_ver="v1.34"
claude_uid="${UID}"
claude_gid="$(id -g)"

cat >kubernetes.repo <<EOF
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/${kube_ver}/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/${kube_ver}/rpm/repodata/repomd.xml.key
EOF

echo "Build date:     ${build_date}"
echo "Image version:  ${image_ver}"
echo "UID and GID:    ${claude_uid} / ${claude_gid}"
echo

podman build \
    -f Containerfile \
    --tag "claudecode:${image_ver}" \
    --build-arg BUILD_DATE="${build_date}" \
    --build-arg IMAGE_VER="${image_ver}" \
    --build-arg CLAUDE_UID="${claude_uid}" \
    --build-arg CLAUDE_GID="${claude_gid}" \
    --unsetlabel org.opencontainers.image.license \
    --unsetlabel org.opencontainers.image.name \
    --unsetlabel name \
    --unsetlabel vendor \
    --unsetlabel version \
    --unsetlabel license

podman tag "claudecode:${image_ver}" claudecode:latest
