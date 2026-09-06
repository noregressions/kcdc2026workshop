# Scenario Cheat Sheet

One page per scenario: what to run, in order, why, and what the output should look like.
Every command is run from the scenario's own directory unless a `cd` is shown.
The `#` line above each command says what that command is for.
PIDs, timestamps, digests and file sizes are run-specific; versions and counts are the invariants.

Scenarios in numeric order below: S01, S02, S03, S04, S05, S07, S08.
The timed workshop route (see `WORKSHOP.md`) runs them as S01 → S04 → S05 → S03, then S07; S02 and S08 are go-deeper material.

Every scenario has a `./scripts/proof-check.sh` that re-runs the lab and asserts the outcomes below still hold.
Passing runs end with `RESULT: PASS` (S01–S05) or `Failed: 0` (S07, S08).

## Before the workshop

```bash
# Report the version of every tool the labs need and flag anything missing or too old.
./scripts/tools-check.sh

# Pull base images, build S01–S05, build the S01/S02 container images, warm the scanner DBs.
./scripts/build-all.sh
```

Ports used by the running apps: S01 8080 (java -jar), S02 8080 (Payara container), S03 8081, S04 8082, S05 8083.

---

## S01 — Spring + Node: shading, bundling, metadata stripping

Tracers: `jackson-databind` (control), `commons-codec` (shaded and relocated), `lodash` (bundled by Vite).
Needs: JDK 21, Maven 3.9+, Node 20+. Full trace also needs `jq`, `syft`, `zip`, Docker.

```bash
cd scenarios/S01-spring-node

# Remove all build output so every observation below comes from this run.
./scripts/clean.sh

# npm install + Vite build of the frontend, then mvn package for normalizer and service.
./scripts/build.sh
```

Prints a `Cleaned:` list, then `Built:` with `frontend/dist/`, `normalizer/target/normalizer-1.0.0.jar`, `service/target/service-1.0.0.jar`.

**Declared versions**

```bash
# Ask Maven which jackson-databind version the service resolved.
mvn -pl service -am dependency:tree -Dincludes=com.fasterxml.jackson.core:jackson-databind
```
```text
[INFO] \- com.fasterxml.jackson.core:jackson-databind:jar:2.19.4:compile
```

```bash
# Ask Maven which commons-codec version the normalizer resolved, before shading.
mvn -pl normalizer dependency:tree -Dincludes=commons-codec:commons-codec
```
```text
[INFO] \- commons-codec:commons-codec:jar:1.17.1:compile
```

```bash
# Ask npm which lodash version the frontend resolved.
(cd frontend && npm ls lodash)
```
```text
checkout-trace-frontend@1.0.0
└── lodash@4.17.21
```

**Jackson in the JAR (control)**

```bash
# Confirm the resolved Jackson jar is physically inside the Spring Boot JAR, name and version intact.
unzip -l service/target/service-1.0.0.jar | grep jackson-databind
```
```text
1679441  ...   BOOT-INF/lib/jackson-databind-2.19.4.jar
```

**commons-codec after shading**

```bash
# Show commons-codec classes now live under the relocated package name.
unzip -l normalizer/target/normalizer-1.0.0.jar | grep 'com/acme/internal/codec' | head

# Show the original package path is gone from the shaded JAR.
unzip -l normalizer/target/normalizer-1.0.0.jar | grep 'org/apache/commons/codec' | head
```
First shows relocated classes (`com/acme/internal/codec/BinaryDecoder.class` ...). Second prints nothing.

```bash
# Read the Maven metadata the shade plugin kept; this is the only remaining identity clue.
unzip -p normalizer/target/normalizer-1.0.0.jar META-INF/maven/commons-codec/commons-codec/pom.properties
```
```text
artifactId=commons-codec
groupId=commons-codec
version=1.17.1
```

```bash
# Scan the shaded JAR; Syft finds commons-codec because that metadata is still present.
syft normalizer/target/normalizer-1.0.0.jar
```
```text
NAME           VERSION  TYPE
commons-codec  1.17.1   java-archive
normalizer     1.0.0    java-archive
```

**Strip the metadata, scan again**

```bash
# Copy the shaded JAR minus META-INF/maven/commons-codec; bytecode untouched. Prints before/after scans.
./scripts/strip-codec-metadata.sh

# Scan the stripped copy to show what the scanner was actually relying on.
syft trace-output/normalizer-no-codec-metadata.jar
```
```text
normalizer                    1.0.0    java-archive
normalizer-no-codec-metadata  UNKNOWN  java-archive
```
commons-codec has vanished from the scan. Bytecode untouched. Software presence ≠ software identifiability.

**lodash in the bundle**

```bash
# List what Vite produced: one minified bundle, no package structure.
find frontend/dist -maxdepth 2 -type f -print

# Scan the bundle; there is no package metadata for Syft to read.
syft frontend/dist
```
```text
frontend/dist/index.html
frontend/dist/assets/index-<hash>.js
frontend/dist/assets/index-<hash>.css
frontend/dist/.vite/manifest.json

No packages discovered
```

**Whole Spring Boot JAR**

```bash
# Confirm the frontend bundle was copied into the service JAR as static resources.
unzip -l service/target/service-1.0.0.jar | grep 'BOOT-INF/classes/static/'

# Confirm the shaded normalizer JAR is nested inside the service JAR.
unzip -l service/target/service-1.0.0.jar | grep 'normalizer-1.0.0.jar'

# Scan the finished application JAR to see the full identifiable inventory.
syft service/target/service-1.0.0.jar
```
34 packages. Relevant rows:
```text
commons-codec     1.17.1   java-archive
commons-codec     1.18.0   java-archive
jackson-databind  2.19.4   java-archive
normalizer        1.0.0    java-archive
service           1.0.0    java-archive
```
No lodash. Two commons-codec versions.

```bash
# Explain the second commons-codec: Spring Boot's BOM manages the version up to 1.18.0 for the service.
mvn -pl service -am dependency:tree -Dincludes=commons-codec:commons-codec -Dverbose
```
```text
[INFO] \- dev.noregressions.trace:normalizer:jar:1.0.0:compile
[INFO]    \- commons-codec:commons-codec:jar:1.18.0:compile (version managed from 1.17.1)
```
Dependency graph ≠ complete physical inventory.

**SBOMs: Maven model vs artefact**

```bash
# Generate CycloneDX SBOMs from the Maven dependency model for every module.
mvn -pl service -am org.cyclonedx:cyclonedx-maven-plugin:2.9.3:makeBom -DoutputFormat=json

# Print the tracer rows from the normalizer and service BOMs side by side.
./scripts/compare-sboms.sh
```
```text
=== normalizer BOM ===
commons-codec	1.17.1	pkg:maven/commons-codec/commons-codec@1.17.1?type=jar

=== service BOM ===
jackson-databind	2.19.4	...
normalizer	1.0.0	...
commons-codec	1.18.0	...
```

```bash
# Generate a second CycloneDX SBOM, this time from the finished JAR's bytes rather than the POM.
mkdir -p trace-output
syft service/target/service-1.0.0.jar -o cyclonedx-json=trace-output/service-syft.cdx.json

# Compare the Maven-model SBOM with the artefact-derived SBOM for the same service.
./scripts/compare-service-sboms.sh
```
```text
=== Maven-generated service SBOM ===
commons-codec	1.18.0
jackson-databind	2.19.4
normalizer	1.0.0

=== Syft-generated service SBOM ===
commons-codec	1.17.1
commons-codec	1.18.0
jackson-databind	2.19.4
normalizer	1.0.0
```
Same format, different inventory. Where the SBOM is generated matters.

**Container image**

```bash
# Build the Docker image, record its digest, and scan the whole image (app + JRE + OS packages).
./scripts/image-trace.sh
```
Builds `registry.example.com/checkout-service:release-123`, writes `trace-output/image.cdx.json`.
```text
Packages      179
Executables   837

commons-codec     1.17.1
commons-codec     1.18.0
jackson-databind  2.19.4
normalizer        1.0.0
```
JAR scan 34 packages, image scan 179. Still no lodash. Application SBOM ≠ container SBOM.

**Optional**

```bash
# Run the service locally and hit its trace endpoint to prove the shaded codec is executing.
java -jar service/target/service-1.0.0.jar
curl 'http://localhost:8080/api/trace?value=Hello%20Supply%20Chain'

# Replay every evidence step non-interactively; writes files into trace-output/.
./scripts/trace.sh

# Re-run the lab and assert every outcome above still holds.
./scripts/proof-check.sh    # flags: --quick, --skip-build, --skip-runtime, --skip-image

# Remove build output; keeps frontend/package-lock.json.
./scripts/clean.sh
```

---

## S02 — Payara + mvnpm: plugin-realm dependency reaches the browser

Tracers: `commons-lang3` (ordinary), `lodash-es` (mvnpm, plugin realm only), `jakarta.jakartaee-web-api` (`provided`), the container's own software.
Needs: JDK 21+, Maven, Docker. Syft and `jq` for the SBOM steps.

```bash
cd scenarios/S02-payara-mvnpm

# Start from nothing: drop previous evidence and Maven output.
rm -rf trace-output && mvn clean

# mvn clean package: esbuild bundles lodash-es into assets/app.js, then the WAR is assembled.
./scripts/build.sh

# Confirm the WAR exists and the generated browser bundle was produced.
ls -lh target/payara-mvnpm-trace-lab-1.0.0.war
find target/generated-web -maxdepth 2 -type f -print
```
```text
target/generated-web/assets/app.js.map
target/generated-web/assets/app.js
```

**Three Maven dependency domains**

```bash
# Ordinary application dependency: appears in the project tree as expected.
mvn dependency:tree -Dincludes=org.apache.commons:commons-lang3
```
```text
[INFO] \- org.apache.commons:commons-lang3:jar:3.18.0:compile
```

```bash
# lodash-es is a plugin dependency, not a project dependency, so the project tree shows nothing.
mvn dependency:tree -Dincludes=org.mvnpm:lodash-es
```
Nothing under the project. `BUILD SUCCESS` only.

```bash
# Ask Maven what it resolved for the esbuild plugin; the plugin's own extra dependencies are still not listed.
mvn dependency:resolve-plugins -DincludeArtifactIds=esbuild-maven-plugin
```
Lists `io.mvnpm:esbuild-maven-plugin:maven-plugin:2.0.0` and its jars. lodash-es is still not listed.

```bash
# Debug-level Maven output shows the real plugin class realm, where lodash-es finally appears.
mvn -X generate-resources 2>&1 | grep 'org.mvnpm:lodash-es'
```
```text
[DEBUG]    org.mvnpm:lodash-es:jar:4.17.21:runtime
[DEBUG]   Included: org.mvnpm:lodash-es:jar:4.17.21
```
Only the plugin execution realm shows it.

**lodash-es is in the bundle but not identifiable**

```bash
# The source map lists every lodash-es module esbuild pulled into app.js.
jq -r '.sources[]' target/generated-web/assets/app.js.map | grep 'lodash'
```
32 lines like `../../../../node_modules/lodash-es/_freeGlobal.js`.

```bash
# Scan the generated bundle as an artefact; no package metadata survives bundling.
syft target/generated-web
```
```text
No packages discovered
```

**WAR boundary**

```bash
# Show both tracers physically inside the WAR: the jar under WEB-INF/lib and the bundle under assets/.
unzip -l target/payara-mvnpm-trace-lab-1.0.0.war | grep -E 'WEB-INF/lib/commons-lang3|assets/app\.js'
```
```text
702952  ...   WEB-INF/lib/commons-lang3-3.18.0.jar
 44987  ...   assets/app.js.map
  8110  ...   assets/app.js
```

```bash
# Scan the WAR; only the Java jar is identifiable, the bundled JS is not.
syft target/payara-mvnpm-trace-lab-1.0.0.war
```
```text
commons-lang3             3.18.0   java-archive
payara-mvnpm-trace-lab    1.0.0    java-archive
```

```bash
# Show the WAR deliberately omits the Jakarta EE API jar (provided by the server).
unzip -l target/payara-mvnpm-trace-lab-1.0.0.war | grep 'WEB-INF/lib/'

# Confirm the API is declared with provided scope, which is why it is absent from the WAR.
mvn dependency:tree -Dincludes=jakarta.platform:jakarta.jakartaee-web-api
```
First lists only `commons-lang3-3.18.0.jar`. Second shows `jakarta.jakartaee-web-api:jar:11.0.0:provided`.

**Two CycloneDX SBOMs**

```bash
# Generate a CycloneDX SBOM from the Maven model and pull out the three tracers.
mvn org.cyclonedx:cyclonedx-maven-plugin:2.9.3:makeBom -DoutputFormat=json
jq -r '.components[] | [.name, .version, (.scope // "-")] | @tsv' target/bom.json \
  | grep -E 'commons-lang3|jakarta.jakartaee-web-api|lodash-es'
```
```text
jakarta.jakartaee-web-api    11.0.0    required
commons-lang3                3.18.0    required
```
27 components. `provided` became `required`. lodash-es absent.

```bash
# Generate a CycloneDX SBOM from the WAR's bytes and pull out the same tracers.
mkdir -p trace-output
syft target/payara-mvnpm-trace-lab-1.0.0.war -o cyclonedx-json=trace-output/war-syft.cdx.json
jq -r '.components[] | [.name, .version, (.scope // "-")] | @tsv' trace-output/war-syft.cdx.json \
  | grep -E 'commons-lang3|jakarta|lodash-es|payara-mvnpm'
```
```text
commons-lang3            3.18.0    -
payara-mvnpm-trace-lab   1.0.0     -
```
The Jakarta API disappears and lodash-es never appears. Maven `provided` ≠ CycloneDX `required` ≠ physical presence.

**Runtime and container**

```bash
# Build the Payara image with the WAR and start it detached on port 8080.
./scripts/run.sh

# Call the deployed app to prove commons-lang3 is executing inside Payara.
curl -sS 'http://localhost:8080/trace/api/info?name=runtime%20trace' | jq
```
```json
{
  "message": "Hello Runtime trace",
  "application": "payara-mvnpm-trace-lab",
  "javaLibrary": "commons-lang3",
  "server": "Payara"
}
```

```bash
# Scan the whole container image: Payara, the JDK and OS packages join the inventory.
syft payara-mvnpm-trace-lab:local
```
589 packages, 825 executables. Includes `commons-lang3 3.18.0`, `payara-api 7.2026.7`, `zulu21-jre 21.0.11-3 deb`. Still no lodash-es.

```bash
# Remove the running Payara container.
./scripts/stop.sh

# Replay the dependency-domain and WAR evidence steps non-interactively.
./scripts/trace-mvnpm.sh

# Build the image and write its Syft CycloneDX SBOM to trace-output/image.cdx.json.
./scripts/image-trace.sh

# Re-run the lab and assert every outcome above still holds.
./scripts/proof-check.sh    # flags: --quick, --skip-build, --skip-runtime, --skip-image

# Remove target/ and trace-output/.
./scripts/clean.sh
```

---

## S03 — Python PEP 517: the build backend writes the package

Tracers: `reportkit` (direct) → `tracehook-demo` (transitive sdist with its own build backend).
Needs: Python 3.11+, `curl`, `tar`, `unzip`. `jq` optional. Fixtures are local, no PyPI access needed.

```bash
cd scenarios/S03-python-pep517

# Remove the venv and previous evidence so the install below is a fresh one.
./scripts/clean.sh

# The only thing the application declares.
cat requirements.txt
```
```text
reportkit==1.0.0
```

```bash
# Read the direct package's metadata to find its transitive requirement.
unzip -p python-repo/reportkit-1.0.0-py3-none-any.whl reportkit-1.0.0.dist-info/METADATA
```
```text
Name: reportkit
Version: 1.0.0
Requires-Dist: tracehook-demo==1.0.0
```

```bash
# List the transitive source distribution: two files, no package code.
tar -tzf python-repo/tracehook_demo-1.0.0.tar.gz
```
```text
tracehook_demo-1.0.0/pyproject.toml
tracehook_demo-1.0.0/tracehook_backend.py
```
No `__init__.py`, no `build-hook.json`. The sdist has no package code.

```bash
# Read the build-system declaration: the sdist names its own local module as the PEP 517 backend.
tar -xOzf python-repo/tracehook_demo-1.0.0.tar.gz tracehook_demo-1.0.0/pyproject.toml
```
```toml
[build-system]
requires = []
build-backend = "tracehook_backend"
backend-path = ["."]
```

**Install and watch the backend run**

```bash
# Create .venv and pip install from the local repo; pip runs the backend to build the wheel.
./scripts/build.sh
```
```text
  Building wheel for tracehook-demo (pyproject.toml): finished with status 'done'
Successfully built tracehook-demo
Successfully installed reportkit-1.0.0 tracehook-demo-1.0.0
```
Full log in `trace-output/pip-install.log`.

```bash
# Compare the one-line requirements file with what actually got installed.
.venv/bin/python -m pip freeze
```
```text
reportkit==1.0.0
tracehook-demo==1.0.0
```

```bash
# Look for the two files that were not in the sdist; they now exist in site-packages.
find .venv \( -path '*site-packages/tracehook_demo/__init__.py' -o -path '*site-packages/tracehook_demo/build-hook.json' \) -print
```
```text
.venv/lib/python3.x/site-packages/tracehook_demo/__init__.py
.venv/lib/python3.x/site-packages/tracehook_demo/build-hook.json
```
Both files exist now. Neither was in the sdist.

```bash
# Read the marker the backend wrote while building the wheel.
find .venv -path '*site-packages/tracehook_demo/build-hook.json' -exec cat {} \;
```
```json
{
  "event": "pep517-build-backend-executed",
  "generatedBy": "tracehook_backend.build_wheel",
  "package": "tracehook-demo",
  "version": "1.0.0"
}
```

**Runtime**

```bash
# Import the direct dependency and show it returns the backend-generated content.
.venv/bin/python -c 'import reportkit; print(reportkit.runtime_trace())'
```
Prints the same dict, `'event': 'pep517-build-backend-executed'`.

```bash
# Start the small HTTP app detached on port 8081.
./scripts/run.sh
```
```text
Runtime started as PID <pid>
Open:  http://localhost:8081/
Trace: http://localhost:8081/trace
```

```bash
# Fetch the trace endpoint; the generated content is now runtime behaviour.
curl -sS http://localhost:8081/trace | jq
```
Same JSON as `build-hook.json` above.

```bash
# Stop the app using the saved PID.
./scripts/stop.sh

# Replay the declaration, sdist, backend and installed-marker steps non-interactively.
./scripts/trace-python.sh

# Re-run the lab and assert every outcome above still holds.
./scripts/proof-check.sh       # flags: --quick, --skip-build, --skip-runtime

# Stop the app if running, then remove .venv/ and trace-output/.
./scripts/clean.sh
```

---

## S04 — Maven plugin hidden content: empty dependency graph, injected route

Tracers: `trace-injector-maven-plugin` and its payload `trace-route-payload`. Neither is an application dependency.
Needs: JDK 21+, Maven 3.9+, `curl`, `unzip`. `jq` and Syft optional. All `mvn` calls use the scenario-local repo `.maven-repo`.

```bash
cd scenarios/S04-maven-plugin-hidden-content

# Remove target/, tooling output and evidence; keeps the local Maven repo.
./scripts/clean.sh

# Build the plugin and payload into .maven-repo, then build the app with the plugin running.
./scripts/build.sh
```
```text
[INFO] --- trace-injector:1.0.0:inject-route (inject-build-route) @ maven-plugin-hidden-content ---
[INFO] Injected route: /hidden/build-info
[INFO] Compiling 3 source files with javac [debug release 21] to target/classes
[INFO] BUILD SUCCESS
```
Three source files compiled, only two exist in `src/`.

**Three Maven domains**

```bash
# The application dependency graph: the plugin and payload are not in it.
mvn -Dmaven.repo.local="$PWD/.maven-repo" dependency:tree
```
```text
[INFO] dev.noregressions.trace:maven-plugin-hidden-content:jar:1.0.0
```
Nothing beneath it. Empty graph.

```bash
# The plugin dependency graph: here the plugin and its transitive payload appear.
mvn -Dmaven.repo.local="$PWD/.maven-repo" dependency:resolve-plugins -DincludeArtifactIds=trace-injector-maven-plugin
```
```text
[INFO]    dev.noregressions.trace:trace-injector-maven-plugin:maven-plugin:1.0.0:runtime
[INFO]       dev.noregressions.trace:trace-injector-maven-plugin:jar:1.0.0
[INFO]       dev.noregressions.trace:trace-route-payload:jar:1.0.0
```

```bash
# The plugin execution realm: debug output proves both jars were loaded to run the mojo.
mvn -Dmaven.repo.local="$PWD/.maven-repo" -X generate-sources 2>&1 | grep -E 'trace-injector|trace-route-payload'
```
```text
[DEBUG] Created new class realm plugin>dev.noregressions.trace:trace-injector-maven-plugin:1.0.0
[DEBUG]   Included: dev.noregressions.trace:trace-injector-maven-plugin:jar:1.0.0
[DEBUG]   Included: dev.noregressions.trace:trace-route-payload:jar:1.0.0
```

**Generated content**

```bash
# List the Java source and resources the plugin wrote into target/ during the build.
find target/generated-sources target/generated-resources -type f -print
```
```text
target/generated-sources/trace-injector/dev/noregressions/trace/s04/generated/GeneratedTraceRoute.java
target/generated-resources/trace-injector/META-INF/trace-lab/plugin-injection.properties
target/generated-resources/trace-injector/META-INF/services/dev.noregressions.trace.s04.TraceRoute
```

```bash
# Read the marker the plugin left naming itself, its payload and the injected route.
cat target/generated-resources/trace-injector/META-INF/trace-lab/plugin-injection.properties
```
```text
plugin=trace-injector-maven-plugin
payload=trace-route-payload
route=/hidden/build-info
```

**In the JAR**

```bash
# Confirm the generated class, ServiceLoader entry and marker were packaged into the final JAR.
unzip -l target/maven-plugin-hidden-content-1.0.0.jar | grep -E 'GeneratedTraceRoute|META-INF/services|plugin-injection'
```
```text
META-INF/trace-lab/plugin-injection.properties
META-INF/services/dev.noregressions.trace.s04.TraceRoute
dev/noregressions/trace/s04/generated/GeneratedTraceRoute.class
```

```bash
# Disassemble the shipped class to prove the route string is in the bytecode.
javap -classpath target/maven-plugin-hidden-content-1.0.0.jar -c -p dev.noregressions.trace.s04.generated.GeneratedTraceRoute
```
```text
  public java.lang.String path();
       0: ldc           #7                  // String /hidden/build-info
```

**Scanners see none of it**

```bash
# Scan the JAR; only the application itself is identified.
syft target/maven-plugin-hidden-content-1.0.0.jar
```
```text
NAME                         VERSION  TYPE
maven-plugin-hidden-content  1.0.0    java-archive
```

```bash
# Generate the standard CycloneDX SBOM from the Maven model; it is empty.
mvn -Dmaven.repo.local="$PWD/.maven-repo" org.cyclonedx:cyclonedx-maven-plugin:2.9.3:makeBom -DoutputFormat=json
```
```text
[INFO] CycloneDX: Creating BOM version 1.6 with 0 component(s)
```

**Runtime**

```bash
# Start the app detached on port 8082.
./scripts/run.sh

# Control endpoint defined in src/: proves the app is up.
curl -sS http://localhost:8082/health | jq

# Endpoint that exists only because the plugin injected it at build time.
curl -sS http://localhost:8082/hidden/build-info | jq
```
Health returns `{"application": "maven-plugin-hidden-content", "status": "UP"}`. Build-info returns:
```json
{
  "message": "This runtime endpoint came from a transitive Maven plugin dependency.",
  "origin": "trace-route-payload",
  "introducedBy": "trace-injector-maven-plugin",
  "route": "/hidden/build-info"
}
```

```bash
# Stop the app using the saved PID.
./scripts/stop.sh

# Replay the dependency-domain and generated-content steps non-interactively.
./scripts/trace-plugin.sh

# Re-run the lab and assert every outcome above still holds.
./scripts/proof-check.sh

# Remove build output; keeps .maven-repo. Add rm -rf .maven-repo for a cold resolution run.
./scripts/clean.sh
```

---

## S05 — npm prepack: the package generates itself while packing

Tracer: `trace-route-package`, whose `prepack` script writes `dist/` before the tarball is made.
Needs: Node 20+, npm, `curl`, `tar`. `jq` and Syft optional. No external npm packages.

```bash
cd scenarios/S05-node-prepack

# Remove node_modules, the packed tarball, generated dist/ and evidence.
./scripts/clean.sh

# npm pack the package (running its prepack hook), then npm install the app from that tarball.
./scripts/build.sh
```
```text
npm notice run trace-route-package@1.0.0 prepack
npm notice run node scripts/generate-dist.js
generated dist/index.js for /hidden/prepack-info
generated dist/prepack-evidence.json
npm notice Tarball Contents
npm notice 435B dist/index.js
npm notice 334B dist/prepack-evidence.json
npm notice 300B package.json
npm notice total files: 3

added 1 package
└── trace-route-package@1.0.0
```
Tarball lands in `npm-repo/trace-route-package-1.0.0.tgz`. Logs in `trace-output/`.

**Source vs tarball vs installed**

```bash
# List the package source after packing: generator script, its input, and the dist/ it produced.
find packages/trace-route-package -maxdepth 3 -type f -print | sort
```
```text
packages/trace-route-package/build-input/route.json
packages/trace-route-package/dist/index.js
packages/trace-route-package/dist/prepack-evidence.json
packages/trace-route-package/package.json
packages/trace-route-package/scripts/generate-dist.js
```

```bash
# List the tarball: only dist/ and package.json shipped.
tar -tzf npm-repo/trace-route-package-1.0.0.tgz
```
```text
package/dist/index.js
package/package.json
package/dist/prepack-evidence.json
```
The generator script and its input are not in the tarball. Only its output is.

```bash
# Read the provenance marker the prepack script wrote into the tarball.
tar -xOzf npm-repo/trace-route-package-1.0.0.tgz package/dist/prepack-evidence.json | jq
```
```json
{
  "event": "npm-prepack-generated",
  "package": "trace-route-package",
  "version": "1.0.0",
  "generatedBy": "npm lifecycle prepack -> scripts/generate-dist.js",
  "route": "/hidden/prepack-info"
}
```

```bash
# Confirm the installed copy has the same three files.
find node_modules/trace-route-package -maxdepth 3 -type f -print | sort

# Confirm the marker survived install unchanged.
cat node_modules/trace-route-package/dist/prepack-evidence.json | jq

# npm's own view of the installed tree: one dependency, correctly identified.
npm ls --all
```

**Evidence views**

```bash
# Generate npm's CycloneDX SBOM and list its components.
npm sbom --sbom-format cyclonedx > trace-output/npm-sbom.json
jq -r '.components[]? | [.name, .version] | @tsv' trace-output/npm-sbom.json
```
```text
trace-route-package	1.0.0
```

```bash
# Scan only the installed package directory; Syft has no project context here.
syft node_modules/trace-route-package
```
```text
No packages discovered
```

```bash
# Scan the whole project; with package.json and the lockfile present Syft identifies both packages.
syft dir:.
```
```text
NAME                     VERSION  TYPE
node-prepack-trace-lab   1.0.0    npm
trace-route-package      1.0.0    npm
```
Same package, 0 or 2 results depending on scan context.

**Runtime**

```bash
# Start the Node app detached on port 8083.
./scripts/run.sh
```
```text
Runtime started as PID <pid>
Open:   http://localhost:8083/
Health: http://localhost:8083/health
Trace:  http://localhost:8083/hidden/prepack-info
```

```bash
# Route served by the prepack-generated dist/index.js.
curl -sS http://localhost:8083/hidden/prepack-info | jq

# Control endpoint defined in the app's own source.
curl -sS http://localhost:8083/health | jq

# Stop the app using the saved PID.
./scripts/stop.sh

# Re-run the lab and assert every outcome above still holds.
./scripts/proof-check.sh

# Stop the app if running, then remove all generated and installed state.
./scripts/clean.sh
```
Prepack-info returns the same JSON as `prepack-evidence.json`. Health returns `{"application": "node-prepack-trace-lab", "status": "UP"}`.

Related: `malicious-variant/` (used by investigation T08) builds two tarballs. Case A hides the payload in the prepack script that never ships. Case B writes the payload into the shipped `dist/index.js`.

---

## S07 — Reverse provenance on S01: from anonymous image to signed attestation

Reuses S01's source in a throwaway copy under `work/s01`. Does not modify S01.
Needs: Docker, Maven, Java 21, `syft`, `cosign`, `curl`. Starts a local `registry:2` on port 5000 if none is running.

```bash
cd scenarios/S07-provenance-s01

# Copy S01, build it exactly as shipped, then try to trace the image back to a commit and fail.
./scripts/build-baseline.sh
```
```text
-- Which commit produced this? (git.properties in the JAR) --
   MISSING — the JAR names no commit
-- Which repo/commit built this image? (OCI labels) --
   {"org.opencontainers.image.version":"22.04"}
-- What is inside? (an SBOM travelling with the image) --
   NONE
-- Can we prove the image is what we think? (a signature) --
   NONE — only a mutable tag names it
```
The only label is inherited from the Ubuntu base image.

```bash
# Rebuild with four provenance layers: git.properties, OCI labels, digest-keyed SBOM, cosign signature + attestation.
./scripts/add-provenance.sh
```
Four layers, printed in sequence. Commit ids, times and digests will differ.

Layer 1, `git.properties` recovered from the JAR (git-commit-id-maven-plugin):
```text
git.branch=master
git.commit.id.abbrev=<abbrev>
git.remote.origin.url=https://github.com/herodevs/kcdc2026workshop.git
```

Layer 2, OCI labels from `docker image inspect` (Dockerfile LABELs from build args):
```json
{
    "org.opencontainers.image.revision": "<full sha>",
    "org.opencontainers.image.source": "https://github.com/herodevs/kcdc2026workshop.git",
    "org.opencontainers.image.version": "1.0.0"
}
```

Layer 3, image pushed to the local registry to obtain a digest, then Syft SBOM of that digest:
```text
Image digest: sha256:<digest>
SBOM components: ~5040
```

Layer 4, `cosign sign` and `cosign attest` on the digest, then verified with the public key only:
```text
  - The cosign claims were validated
  - The signatures were verified against the specified public key

signature:   VERIFIED
attestation: VERIFIED (the SBOM travels bound to the digest)
```

Outputs in `results/`: `image-digest.txt`, `checkout-service.cdx.json`, `cosign.key`, `cosign.pub`. Committed examples in `evidence/`.

```bash
# Assert the baseline has no provenance and the provenance image has all four layers, signature included.
./scripts/proof-check.sh
```
```text
PASS  baseline image has NO revision label
PASS  JAR carries git.properties with a commit id
PASS  prov image has a revision label
PASS  prov image has a source label
PASS  SBOM lists the jackson-databind tracer
PASS  image signature verifies
PASS  SBOM attestation verifies

Passed: 7
Failed: 0
```

```bash
# No clean script. work/ and results/ are gitignored and rebuilt each run. Remove the local registry:
docker rm -f s07-registry
```

Layers 1 to 3 are claims. Layer 4 is the first one an outsider can verify.

---

## S08 — Extended SBOM: what built this, not just what ships

Runs the standard CycloneDX plugin and SBOM+ against the S04 and S01 POMs.
Needs: S04 built, S01 checked out, JDK 21+, Maven 3.9+, `jq`.

```bash
cd scenarios/S08-extended-sbom

# Optional, offline machines: install the SBOM+ plugin into ~/.m2 so the scans resolve without network.
./scripts/seed-plugin.sh

# Run both generators on the S04 POM and print what each says about the plugin and payload.
./scripts/scan-s04.sh
```
```text
===== S04: what each SBOM says =====
standard : 0 components    specVersion=1.6
extended : 171 components  excluded=171  specVersion=1.5
SBOM+ report: 194 rows across 1 module(s)  BUILD_TOOLING=194  unresolved=0

-- The S04 tracers --
standard SBOM:
   (absent)
extended SBOM:
   trace-injector-maven-plugin  1.0.0  excluded  ...?type=maven-plugin
   trace-route-payload          1.0.0  excluded
SBOM+ report (origin, scope, path):
   ...  BUILD_TOOLING  plugin             trace-injector-maven-plugin:1.0.0  (declared directly)
   ...  BUILD_TOOLING  plugin-transitive  trace-route-payload:1.0.0          via trace-injector-maven-plugin
```
Standard SBOM is empty and correct. Extended names the plugin and payload as build tooling, marked `excluded`.

```bash
# Run both generators across the whole S01 reactor (makeAggregateBom vs scan-aggregate).
./scripts/scan-s01.sh
```
On a checkout that is packaged but not installed:
```text
[WARNING] SBOM+ scan: 1 dependency could not be resolved for dev.noregressions.trace:service

===== S01: what each SBOM says =====
standard : 38 components   (no scope)=2  required=36  specVersion=1.6
extended : 265 components  excluded=230  required=35  specVersion=1.5
SBOM+ report: 642 rows across 3 module(s)  BOM=1  BUILD_TOOLING=569  MAIN_BUILD=72  unresolved=1
```
Extended SBOM adds `maven-shade-plugin 3.6.2` (excluded), `spring-boot-dependencies 3.5.12` (excluded, `?type=pom`), and shows `jackson-databind 2.19.4` twice: once as `MAIN_BUILD compile`, once as `BUILD_TOOLING` via `spring-boot-maven-plugin`.

```bash
# Install S01 into the local repo so SBOM+ can resolve the sibling normalizer module, then re-scan.
(cd ../S01-spring-node && mvn -q install -DskipTests) && ./scripts/scan-s01.sh
```
```text
extended : 267 components  excluded=230  required=37  specVersion=1.5
SBOM+ report: 644 rows across 3 module(s)  ...  MAIN_BUILD=74  unresolved=0
   only in standard : dev.noregressions.trace:service:1.0.0
   only in extended : 230 (build tooling and the BOM import)
   in both          : 37
```
With `normalizer` installed, the two `required` sets agree exactly.

Outputs in `results/s04/` and `results/s01/`: `standard.cdx.json`, `plus.cdx.json`, `plus.report.json`.

```bash
# Re-run both scans silently and assert the 13 claims above still hold.
./scripts/proof-check.sh    # 13 PASS lines, then Passed: 13 / Failed: 0

# Remove results/.
./scripts/clean.sh          # S08 results removed.
```

The extended SBOM moves one boundary to the right: it covers software that executes during the build. Neither SBOM describes bytes; S04 and S07 do that.
