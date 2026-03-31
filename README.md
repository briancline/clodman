# clodman

Claude Code...in a Podman container. Primarily for the security-conscious, and because I already use dev containers a lot in my workflow, so this is a very natural fit for me.

The container has lots of dev tools, linters, some convenience tools needed/preferred by Claude's built-in tools, and a few Kubernetes tools.

Currently includes:
 * Python, flake8, pylint, mypy, uv
 * Golang
 * Ansible
 * jq, yq, ripgrep
 * Skopeo, Hadolint
 * [Age](https://github.com/filosottile/age) and [SOPS](https://github.com/getsops/sops)
 * kubectl, kustomize, helm, kubeconform, stern
 * A few more odds and ends; see the Containerfile for a detailed list.


## Building/Installing
```
$ ./build.sh
$ cp clodman ~/.local/bin  # or wherever you want your personal bin scripts
```


## Using
```
$ cd ~/code/myproject
$ clodman
```


## How it works

Once an image is built, I `cd` to whatever project directory I'm working on that I want Claude's assistance with, and I just run `clodman`. The container starts straight into `claude` in the current directory -- this works nicely in a vscode terminal pane. Any arguments to `clodman` are passed straight to `claude`.

Claude effectively only sees that project, nothing else. The current working directory at start time gets bind-mounted into the container *at the same path*, since Claude saves per-project information/history based on the directory path. (Claude's `~/.claude/` and `~/.claude.json` also get bind-mounted as well -- and a few other random items; see the `clodman` script for everything.)

Each container instance is ephemeral (`podman run --rm`), so it won't hang around after.

A combination of the static uid/gid in the Containerfile (lines 75-76) and running the container with `--userns=keep-id` help keep file permissions problems at bay without subuid/subgid worries. On Fedora/RHEL/etc distros, the `:z` option on the mounts helps get around common SELinux problems with container bind mounts too.

The build also places a `/tools.txt` in the container so I can quickly tell Claude to read it and find out what tools it has available to it. For similar purposes, the output of `dnf list --installed` also gets written to `/packages.txt` for a longer detailed list without having to wait on dnf, as it will have no cache at runtime.


## Caveats

 * It uses podman (because I use Fedora on my personal system and I just strongly prefer podman); docker is *probably* fully drop-in as most commands are near identical.
 * I **do not** publish my built images on any public registry since I have no need to. Also, if someone wants this, I'd rather them do their own image build (and know and be comfortable with what their own image contains).
 * The container image is 2GB+, but that's to be expected in a general purpose dev container with a variety of tools available.
 * The Containerfile hardcodes the container user's uid/gid to help avoid permissions issues. Will probably make this a dynamic var in the future, passed in at build time.
