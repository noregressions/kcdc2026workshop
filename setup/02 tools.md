---
id: setup-tools
oneliner: "Install commands for macOS and Linux, plus what Podman can and cannot substitute for."
---

# Install Before the Workshop

Install the tooling below before attending the workshop.

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

Requirements:

```text
JDK      21+
Maven    3.9+
Node.js  20+
Python   3.11+
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

Authentication is covered in [`03 ACCOUNTS-AND-KEYS.md`](./03%20ACCOUNTS-AND-KEYS.md).

### Docker

Install Docker Desktop.

Verify:

```bash
docker version
docker scout version
```

Docker Desktop includes Docker Scout.

---

# Linux

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

---

# Podman alternative

Podman can be used instead of Docker for the basic S01 and S02 container build/run stages.

However, the repository currently invokes `docker` directly, so Podman is not a completely transparent replacement.

## macOS

```bash
brew install podman

podman machine init
podman machine start
podman info
```

## Debian / Ubuntu

```bash
sudo apt-get update
sudo apt-get install -y podman

podman info
```

## Important limitations

The complete workshop still expects Docker because:

```text
T02  Docker Scout
T03  Trivy image source is explicitly Docker
T04  Grype image source is explicitly Docker
```

The S01 and S02 scripts also currently invoke commands such as:

```text
docker build
docker run
docker rm
docker image inspect
```

If you want to use Podman for those scenario stages, either run the equivalent `podman` commands manually or use a Docker-compatible Podman shim/alias that works in your environment.

Do not assume Podman makes T02 Docker Scout available.

---

# Tools supplied by other prerequisites

You do not need to install these separately:

```text
npm audit
    supplied by npm

jar / javap
    supplied by the JDK

pip
    supplied by Python

CycloneDX Maven Plugin
Maven Shade Plugin
Spring Boot Maven Plugin
esbuild-maven-plugin
mvnpm artefacts
OWASP Dependency-Check Maven Plugin
    resolved by Maven
```

---

# Final local verification

The repository can check all of this for you:

```bash
./scripts/tools-check.sh
```

It reports the version of every tool it finds, flags anything below the
workshop minimum, and prints installation instructions with a link for
anything missing. It installs nothing and changes nothing. Exit status is
non-zero if a required tool is missing or too old.

To see the install instructions for every tool — useful when preparing a
machine you do not have in front of you:

```bash
./scripts/tools-check.sh --urls
```

The equivalent manual checks are:

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
