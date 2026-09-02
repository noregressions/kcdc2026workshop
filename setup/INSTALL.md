---
id: setup-install
oneliner: "Copy-paste installation commands for macOS and Linux, Podman setup, and binary verification checks."
track: reference
---

# Installation Transcripts

Detailed installation and environment configuration commands corresponding to [`02 tools.md`](./02%20tools.md). Run `./scripts/tools-check.sh` to determine missing packages.

## macOS (Homebrew)

### Core Development and Analysis Tools

```bash
brew install \
  openjdk@21 \
  maven \
  node \
  python \
  jq \
  syft \
  grype \
  trivy \
  pipx
```

Verify installations:

```bash
java -version
javac -version
mvn --version

node --version
npm --version

python3 --version
python3 -m pip --version
```

### pip-audit

```bash
pipx ensurepath
pipx install pip-audit
pip-audit --version
```

### Snyk CLI

```bash
npm install -g snyk
snyk --version
```

See [`03 ACCOUNTS-AND-KEYS.md`](./03%20ACCOUNTS-AND-KEYS.md) for authentication.

### Docker

Install Docker Desktop.

Verify:

```bash
docker version
docker scout version
```

## Linux (Debian / Ubuntu APT)

### Base Utilities

```bash
sudo apt-get update

sudo apt-get install -y \
  git \
  curl \
  jq \
  zip \
  unzip \
  tar \
  python3 \
  python3-pip \
  python3-venv \
  pipx
```

### JDK 21

Install a JDK 21 distribution (such as `temurin-21-jdk` from Adoptium).

Verify:

```bash
java -version
javac -version
```

### Maven

```bash
sudo apt-get install -y maven
mvn --version
```

Maven 3.9+ is required.

### Node.js

Node.js 20+ is required. Installation via `nvm`:

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.6/install.sh | bash
. "$HOME/.nvm/nvm.sh"

nvm install 24
```

Verify:

```bash
node --version
npm --version
```

### pip-audit

```bash
pipx ensurepath
pipx install pip-audit
pip-audit --version
```

### Syft

```bash
curl -sSfL https://get.anchore.io/syft \
  | sudo sh -s -- -b /usr/local/bin

syft version
```

### Grype

```bash
curl -sSfL https://get.anchore.io/grype \
  | sudo sh -s -- -b /usr/local/bin

grype version
```

### Trivy

Install Trivy from the Aqua Security package repository.

Verify:

```bash
trivy --version
```

### Snyk CLI

```bash
npm install -g snyk
snyk --version
```

### Docker

Install Docker Engine or Docker Desktop for Linux.

Verify:

```bash
docker version
docker scout version
```

## Podman Configuration

Podman compatibility is limited to scenarios S01/S02 container builds. See constraints in [`02 tools.md`](./02%20tools.md).

### macOS

```bash
brew install podman
podman machine init
podman machine start
podman info
```

### Debian / Ubuntu

```bash
sudo apt-get update
sudo apt-get install -y podman
podman info
```

## Manual Verification Matrix

Automated verification is provided by `./scripts/tools-check.sh`. Manual validation equivalents:

```bash
git --version
bash --version

java -version
javac -version
mvn --version

node --version
npm --version

python3 --version
python3 -m pip --version

jq --version
curl --version
zip -v
unzip -v
tar --version

docker version
docker scout version

syft version
snyk --version
trivy --version
grype version
pip-audit --version
```

For T06:

```bash
printenv NVD_API_KEY >/dev/null && \
  echo "NVD API key: configured" || \
  echo "NVD API key: not configured"
```
