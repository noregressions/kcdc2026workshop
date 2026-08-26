---
id: setup-install
oneliner: "Full copy-paste install transcripts for macOS and Debian/Ubuntu, Podman setup, and the manual verification commands."
track: reference
---

# Install Transcripts

The copy-paste detail behind [`02 tools.md`](./02%20tools.md). Run
`./scripts/tools-check.sh` first — it tells you which of these you actually
need, and `./scripts/tools-check.sh --urls` prints an installation link for
every tool.

## macOS

The commands below assume Homebrew is installed.

### Core development and analysis tools

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

Verify:

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

Docker Desktop includes Docker Scout.

## Linux

The examples below use Debian/Ubuntu package names.

### Base utilities

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

Install a JDK 21 distribution.

For example, with Eclipse Temurin, install `temurin-21-jdk` from the Adoptium repository.

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

The workshop requires Maven 3.9 or newer. If your distribution ships an older Maven, install a current Maven 3.9.x binary distribution instead.

### Node.js

The repository requires Node.js 20 or newer.

Using `nvm` avoids old distribution packages:

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

Install Trivy using Aqua Security's package repository for your distribution.

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

Install Docker Desktop for Linux or Docker Engine.

Verify:

```bash
docker version
docker scout version
```

If Docker Scout is not present, install the Docker Scout CLI separately.

## Podman

Podman can substitute for Docker only in the S01/S02 container build and run
stages — see the limitations in [`02 tools.md`](./02%20tools.md).

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

## Manual verification

`./scripts/tools-check.sh` performs all of these checks for you. The
equivalents by hand:

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
printenv NVD_API_KEY >/dev/null &&
  echo "NVD API key: configured" ||
  echo "NVD API key: not configured"
```
