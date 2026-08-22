# Payara + mvnpm Trace Lab — Trace Plan

This lab follows four different kinds of software into one container:

```text
ordinary Java dependency
    commons-lang3
        ↓
    WEB-INF/lib

npm-origin build dependency
    org.mvnpm:lodash-es
        ↓ esbuild Maven plugin
    assets/app.js

provided platform API
    Jakarta EE Web Profile
        ↓
    not packaged in WAR
        ↓
    supplied by Payara

server/runtime software
    Payara + JDK + OS
        ↓
    container image
```

The important question is not just "what are the dependencies?" It is how each kind of dependency enters the build and what evidence of its original identity survives at each boundary.

## 1. Source declarations

### Why we need to do this

We need a baseline for what the developer intended. The POM contains both application dependencies and build-tool dependencies, but they do not have the same packaging semantics.

### How we're going to do it

Look at `pom.xml` and distinguish:

- `commons-lang3` under normal project `<dependencies>`;
- Jakarta EE API with `provided` scope;
- `lodash-es` under the **esbuild plugin's** `<dependencies>`.

That last placement matters: Maven plugin dependencies are dependencies of the build tool, not normal dependencies of the WAR project.

## 2. Build the WAR

### Run

```bash
./scripts/build.sh
```

### Why we need to do this

The source declarations tell us intent. The build gives us the transformed artefact that actually ships.

### How we're going to do it

Maven compiles the servlet, resolves the Java application dependency, runs the esbuild plugin during `generate-resources`, and then the WAR plugin adds the generated browser assets to the WAR.

mvnpm publishes npm packages as Maven artifacts, and the esbuild Maven plugin supports using those Maven dependencies as web build inputs without requiring a separate Node/npm installation.

## 3. Compare application dependencies with build-time mvnpm dependencies

A normal Maven project dependency and a Maven plugin dependency are resolved in different dependency graphs. We will inspect them separately rather than hide the distinction inside `trace-mvnpm.sh`.

### 3.1 Establish the ordinary application-dependency baseline

#### Why we need to do this

Before looking at mvnpm, establish what a normal Maven application dependency looks like. `commons-lang3` is declared under the project's normal `<dependencies>` section, so it should appear in Maven's project dependency graph and later in `WEB-INF/lib` in the WAR.

#### How we're going to do it

`mvn dependency:tree` asks Maven Dependency Plugin to display the resolved dependency hierarchy for the project. `-Dincludes=org.apache.commons:commons-lang3` filters that resolved graph to the tracer component so unrelated dependencies do not obscure the result.

#### Run

```bash
mvn dependency:tree \
  -Dincludes=org.apache.commons:commons-lang3
```

#### Observed output

```text
[INFO] --- dependency:3.7.0:tree (default-cli) @ payara-mvnpm-trace-lab ---
[INFO] dev.noregressions.trace:payara-mvnpm-trace-lab:war:1.0.0
[INFO] \- org.apache.commons:commons-lang3:jar:3.18.0:compile
```

#### Establish

```text
pom.xml
    commons-lang3:3.18.0

        ↓ Maven project dependency resolution

resolved project graph
    commons-lang3:3.18.0
    scope: compile
```

This is our baseline. Maven sees `commons-lang3:3.18.0` as ordinary application software.

### 3.2 Does the ordinary project graph contain the mvnpm dependency?

#### Why we need to do this

`lodash-es` is not declared as an application dependency. It is a dependency of `esbuild-maven-plugin`. We first want to prove that Maven's ordinary project dependency graph does not treat it like `commons-lang3`.

#### How we're going to do it

Run the same `dependency:tree` query, but filter for the mvnpm coordinate. If no dependency is printed beneath the project, that establishes that `lodash-es` is not part of the normal project dependency graph.

#### Run

```bash
mvn dependency:tree \
  -Dincludes=org.mvnpm:lodash-es
```

#### Observed output

```text
[INFO] --- dependency:3.7.0:tree (default-cli) @ payara-mvnpm-trace-lab ---
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
```

No dependency appeared beneath the project.

#### Establish

```text
pom.xml
    esbuild-maven-plugin
        └── org.mvnpm:lodash-es:4.17.21

        X not part of

Maven project dependency graph
```

The ordinary application dependency graph therefore does not contain `lodash-es`.

#### Why this happens

Maven has separate dependency domains for the project being built and for the plugins that perform the build. `dependency:tree` walks the project's own `<dependencies>` graph: the dependencies that contribute to the project's compile/runtime/test classpaths according to their scopes.

Our `lodash-es` declaration is not in that section. It is nested under:

```text
<build>
  <plugins>
    <plugin>
      esbuild-maven-plugin
      <dependencies>
        lodash-es
```

That makes `lodash-es` a dependency of the **build plugin**, not a dependency of the WAR project. Maven uses such dependencies to augment the plugin's execution class realm. They can therefore influence the bytes produced by the build without appearing in the normal application dependency tree.

This is already an important supply-chain distinction:

```text
project dependency graph
    describes application dependencies

plugin dependency graph / plugin execution realm
    can contain additional software used to produce the application
```

### 3.3 Inspect what `resolve-plugins` can see

#### Why we need to do this

The previous command established that `lodash-es` is outside the application dependency graph. We now want to see what Maven reports when asked about the esbuild build plugin itself.

#### How we're going to do it

The Maven Dependency Plugin's `resolve-plugins` goal reports project plugins and the dependencies associated with the published plugin artifact.

`-DincludeArtifactIds=esbuild-maven-plugin` restricts the report to the plugin we care about.

One subtlety matters here: with the Maven Dependency Plugin version used by this project, this report is built from the plugin artifact's own dependency metadata. It does **not** include the project-specific dependencies that we add under this project's `<plugin><dependencies>` section. Those dependencies are applied when Maven constructs the plugin execution realm.

So this command is useful, but it is not sufficient to prove the presence of our explicitly-added `lodash-es`.

#### Run

```bash
mvn dependency:resolve-plugins \
  -DincludeArtifactIds=esbuild-maven-plugin
```

#### Observed output

The plugin was resolved as:

```text
io.mvnpm:esbuild-maven-plugin:maven-plugin:2.0.0:runtime
```

and Maven reported its published dependency set, including `org.mvnpm:esbuild:0.25.10`, `io.mvnpm:esbuild-java:2.1.1`, and their transitive dependencies.

`org.mvnpm:lodash-es:4.17.21` was **not** listed.

#### Establish

```text
project dependency tree
    lodash-es absent

resolve-plugins report
    lodash-es absent

POM plugin declaration
    lodash-es explicitly present under esbuild-maven-plugin
```

The absence from `resolve-plugins` does not mean the build did not resolve `lodash-es`. It means this reporting goal does not expose the project-specific plugin dependency that Maven adds to the plugin execution realm.

We therefore need to inspect the actual plugin execution next.

### Inspect the actual plugin execution realm

#### Why we need to do this

`lodash-es` is deliberately declared under `esbuild-maven-plugin` rather than under the project's normal `<dependencies>`. Maven therefore does not place it on the application dependency graph or application classpath. Instead, Maven resolves it when constructing the isolated class realm used to execute the plugin.

That distinction matters because build-time software can affect the bytes we ship without ever appearing as an application dependency.

#### How we're going to do it

Run the `generate-resources` phase with Maven debug logging enabled. `-X` exposes Maven's plugin-realm construction. Redirect stderr into stdout with `2>&1`, then filter the generated terminal output to the mvnpm coordinate we care about.

#### Run

```bash
mvn -X generate-resources 2>&1 \
  | grep 'org.mvnpm:lodash-es'
```

#### Observed output

```text
[DEBUG]    org.mvnpm:lodash-es:jar:4.17.21:runtime
[DEBUG]   Included: org.mvnpm:lodash-es:jar:4.17.21
```

#### Establish

```text
project dependency graph
    lodash-es absent

resolve-plugins report
    lodash-es absent

actual esbuild plugin execution realm
    lodash-es:4.17.21 present
```

This happens because the project adds `lodash-es` as a dependency of the Maven plugin itself. Maven resolves that dependency for the plugin's execution environment rather than for the WAR application dependency graph.

The build can therefore use `lodash-es` to produce application bytes even though a normal `dependency:tree` for the WAR never reports it.

## 4. Inspect the generated browser bundle

### Why we need to do this

We have proved that `lodash-es:4.17.21` participated in the plugin execution. That still does not prove it affected the application output. The next boundary is build input → generated browser artefact.

### How we're going to do it

The esbuild execution writes its generated browser bundle under `target/generated-web/assets`. We first establish that the build produced a JavaScript bundle and source map. Then we inspect the source map, which records the source modules that contributed to the generated bundle. This is stronger evidence than merely finding that the plugin had access to `lodash-es`.

### Run

```bash
find target/generated-web -maxdepth 2 -type f -print
```

### Observed output

```text
target/generated-web/assets/app.js.map
target/generated-web/assets/app.js
```

### Establish

The esbuild execution produced browser-facing JavaScript and an accompanying source map.

```text
plugin execution
    lodash-es:4.17.21 available
        ↓ esbuild
output
    assets/app.js
    assets/app.js.map
```

This proves the bundling step produced output. It does **not yet** prove that lodash code contributed to that output.

### Prove that lodash contributed to the generated bundle

#### Why we need to do this

Seeing `lodash-es:4.17.21` in Maven's plugin execution realm only proves that the package was available to esbuild. It does not prove that any lodash code became part of the application.

The source map gives us a second, independent piece of build evidence. Its `sources` array records the source modules represented in the generated JavaScript.

#### How we're going to do it

Use `jq` to read the `sources` array from the generated source map, then filter it to entries containing `lodash`. `jq -r` emits the JSON strings as ordinary terminal text rather than quoted JSON values.

#### Run

```bash
jq -r '.sources[]' target/generated-web/assets/app.js.map \
  | grep 'lodash'
```

#### Observed output

```text
../../../../node_modules/lodash-es/_freeGlobal.js
../../../../node_modules/lodash-es/_root.js
../../../../node_modules/lodash-es/_Symbol.js
../../../../node_modules/lodash-es/_getRawTag.js
../../../../node_modules/lodash-es/_objectToString.js
../../../../node_modules/lodash-es/_baseGetTag.js
../../../../node_modules/lodash-es/isObjectLike.js
../../../../node_modules/lodash-es/isSymbol.js
../../../../node_modules/lodash-es/_arrayMap.js
../../../../node_modules/lodash-es/isArray.js
../../../../node_modules/lodash-es/_baseToString.js
../../../../node_modules/lodash-es/toString.js
../../../../node_modules/lodash-es/_baseSlice.js
../../../../node_modules/lodash-es/_castSlice.js
../../../../node_modules/lodash-es/_hasUnicode.js
../../../../node_modules/lodash-es/_asciiToArray.js
../../../../node_modules/lodash-es/_unicodeToArray.js
../../../../node_modules/lodash-es/_stringToArray.js
../../../../node_modules/lodash-es/_createCaseFirst.js
../../../../node_modules/lodash-es/upperFirst.js
../../../../node_modules/lodash-es/_arrayReduce.js
../../../../node_modules/lodash-es/_basePropertyOf.js
../../../../node_modules/lodash-es/_deburrLetter.js
../../../../node_modules/lodash-es/deburr.js
../../../../node_modules/lodash-es/_asciiWords.js
../../../../node_modules/lodash-es/_hasUnicodeWord.js
../../../../node_modules/lodash-es/_unicodeWords.js
../../../../node_modules/lodash-es/words.js
../../../../node_modules/lodash-es/_createCompounder.js
../../../../node_modules/lodash-es/_escapeHtmlChar.js
../../../../node_modules/lodash-es/escape.js
../../../../node_modules/lodash-es/startCase.js
```

#### Establish

The generated application bundle contains code mapped back to modules from `lodash-es`.

```text
project dependency graph
    lodash-es absent

        ↓

plugin execution realm
    lodash-es:4.17.21 present

        ↓ esbuild

generated app.js + source map
    lodash-es source modules represented
```

This is stronger than simply proving that Maven downloaded the package: we now have build-output evidence that lodash participated in the generated browser code.

The source map paths identify the package as `lodash-es`, but they do not themselves carry the package version. The next check asks whether a package scanner can recover the npm component identity from the generated output alone.

### Scan the generated frontend as an artefact

#### Why we need to do this

We know `lodash-es:4.17.21` contributed source code to `app.js`. Now we deliberately throw away Maven's plugin model and ask an artefact scanner what package identity it can recover from only the generated web files.

This separates **code provenance visible during the build** from **package identity recoverable from the produced artefact**.

#### How we're going to do it

Give Syft only `target/generated-web`. Syft is not being given the POM, Maven plugin realm or mvnpm coordinates; it must infer package identity from the generated files themselves.

#### Run

```bash
syft target/generated-web
```

#### Observed output

```text
✔ Packages [0 packages]
✔ Executables [0 executables]

No packages discovered
```

#### Establish

Syft cannot recover `lodash-es` as a package from the generated frontend artefact, even though the source map proves that lodash modules contributed to the bundle.

```text
build/plugin evidence
    lodash-es:4.17.21

source-map evidence
    lodash-es modules contributed code

artefact-only package scan
    0 packages
```

This is not evidence that lodash code is absent. It shows that **traceability retained by the build is not the same as package discoverability from the generated artefact**.

## 5. Inspect the WAR boundary

### Why we need to do this

The WAR is the first finished application artefact that Payara will deploy. We now want to see what happened to both supply-chain paths when they crossed the packaging boundary:

```text
ordinary Java dependency
    commons-lang3:3.18.0
        ↓
    discrete library JAR?

npm-origin build dependency
    lodash-es:4.17.21
        ↓ esbuild
    generated browser code
        ↓
    packaged in WAR?
```

If both appear, the WAR will demonstrate two very different ways third-party code can be present in the same application: one with an intact package boundary and one only as transformed browser code.

### How we're going to do it

Use normal ZIP/WAR archive inspection. We do not need a specialist tool here: the question is simply which files physically made it into the WAR.

First look for the ordinary Java dependency and the generated web asset in one command.

### Run

```bash
unzip -l target/payara-mvnpm-trace-lab-1.0.0.war \
  | grep -E 'WEB-INF/lib/commons-lang3|assets/app\.js'
```

### Observed output

```text
702952  07-06-2025 18:43   WEB-INF/lib/commons-lang3-3.18.0.jar
 44498  08-21-2026 15:11   assets/app.js.map
  7893  08-21-2026 15:11   assets/app.js
```

### Establish

Both dependency paths reached the same deployable WAR, but with very different surviving evidence:

```text
commons-lang3:3.18.0
    ↓
WEB-INF/lib/commons-lang3-3.18.0.jar
    discrete package boundary and version survive

lodash-es:4.17.21
    ↓ mvnpm plugin dependency
    ↓ esbuild
assets/app.js + assets/app.js.map
    code survives, npm package boundary does not
```

The WAR therefore contains third-party software from both ecosystems, but only one dependency still looks like an ordinary package.

## 6. Scan the WAR as a finished application artefact

### Why we need to do this

We have proved from build evidence that lodash contributed code and from archive inspection that the generated bundle is inside the WAR. Now we deliberately ignore the build history and ask what a package scanner can recover from the deployable WAR itself.

This is the important comparison:

```text
WAR physically contains
    commons-lang3 JAR
    lodash-derived JavaScript

artefact scanner sees
    ?
```

### How we're going to do it

Give Syft only the WAR. Syft can inspect nested Java archives and other package metadata inside the application, but it is not being given the Maven project model or the esbuild plugin execution evidence.

### Run

```bash
syft target/payara-mvnpm-trace-lab-1.0.0.war
```

### Observed

```text
✔ Packages [2 packages]

NAME                     VERSION  TYPE
commons-lang3            3.18.0   java-archive
payara-mvnpm-trace-lab   1.0.0    java-archive
```

`lodash-es` is not reported.

### Establish

Syft can recover the conventional Java dependency because its package boundary and Maven metadata survive inside the WAR. It can also identify the WAR itself.

It cannot recover `lodash-es`, even though the earlier source-map check proved that lodash modules contributed code to `assets/app.js`.

```text
build evidence
    lodash-es:4.17.21 known

source-map evidence
    lodash-es modules contributed

WAR artefact scan
    commons-lang3:3.18.0 visible
    lodash-es not visible
```

This is the central mixed-ecosystem result so far: **code can be present in a deployable artefact without its originating package remaining identifiable to an artefact scanner.**

## 7. Check what the WAR deliberately does not contain

### Why we need to do this

Not every dependency used to build the application should be packaged into the WAR. The Jakarta EE Web API is declared with Maven scope `provided`, which means the application compiles against it but expects the runtime environment to supply it.

This gives us a third supply-chain shape to compare with the first two:

```text
commons-lang3
    compile dependency → packaged as a JAR

lodash-es
    plugin dependency → transformed into JavaScript

Jakarta EE Web API
    provided dependency → intentionally absent from WAR
```

### How we're going to do it

Inspect the WAR's `WEB-INF/lib` directory. If the `provided` boundary is working as intended, we should see the application library but no Jakarta EE API JAR.

### Run

```bash
unzip -l target/payara-mvnpm-trace-lab-1.0.0.war \
  | grep 'WEB-INF/lib/'
```

### Observed

```text
        0  08-21-2026 15:11   WEB-INF/lib/
   702952  07-06-2025 18:43   WEB-INF/lib/commons-lang3-3.18.0.jar
```

### Establish

The WAR contains the normal compile-scope application dependency, `commons-lang3:3.18.0`, but no Jakarta EE API JAR. That is the expected effect of Maven's `provided` scope: the application compiles against the API, but the deployable WAR does not carry it because the runtime is expected to supply it.

This gives us three distinct dependency paths in one application:

```text
commons-lang3:3.18.0
    project dependency, compile scope
        -> survives as WEB-INF/lib/commons-lang3-3.18.0.jar

lodash-es:4.17.21
    plugin dependency
        -> transformed by esbuild into application JavaScript
        -> package identity no longer recovered by Syft

jakarta.jakartaee-web-api:11.0.0
    project dependency, provided scope
        -> used for compilation
        -> deliberately absent from the WAR
        -> expected from Payara at runtime
```

Before relying on that last interpretation, confirm Maven's resolved view of the Jakarta API and its scope.

### Run

```bash
mvn dependency:tree \
  -Dincludes=jakarta.platform:jakarta.jakartaee-web-api
```

### Observed

```text
dev.noregressions.trace:payara-mvnpm-trace-lab:war:1.0.0
\- jakarta.platform:jakarta.jakartaee-web-api:jar:11.0.0:provided
```

### Establish

Maven does resolve `jakarta.jakartaee-web-api:11.0.0`, but with `provided` scope. Combined with the WAR inspection above, this proves the absence of the Jakarta EE API JAR is deliberate: it participates in compilation but is not packaged into the application because the runtime container is expected to provide the implementation.

The three paths are now fully established at the WAR boundary:

```text
commons-lang3:3.18.0
    compile dependency
    -> present as a versioned JAR in WEB-INF/lib

lodash-es:4.17.21
    build-plugin dependency
    -> contributes source modules to generated app.js
    -> package identity not recovered by Syft from the WAR

jakarta.jakartaee-web-api:11.0.0
    provided dependency
    -> present in Maven's dependency model
    -> absent from the WAR by design
    -> expected from Payara at runtime
```

## 8. Run the application on Payara

### Why we need to do this

The WAR is not the complete runtime. Jakarta APIs deliberately omitted from the WAR must be supplied by the server, and the server itself brings a much larger body of software.

### How we're going to do it

The Dockerfile inherits from the Payara Server Web Profile image and copies the WAR into Payara's deployment directory. Starting the container establishes the runtime boundary, but a successful `docker run` does not by itself prove that Payara deployed the WAR successfully. We therefore verify the running servlet separately.

### Run

```bash
./scripts/run.sh
```

### Observed

Docker built the application image from:

```text
payara/server-web:7.2026.7@sha256:989bde76edb44118bad9dba6d2d7ce93b7f0c0aab3577773f8d89a74257d90e7
```

and copied:

```text
target/payara-mvnpm-trace-lab-1.0.0.war
    -> /opt/payara/deployments/trace.war
```

The resulting local image was named:

```text
payara-mvnpm-trace-lab:local
```

and the container started successfully.

### Establish

The deployable WAR has now crossed into a Payara runtime image. This proves the image construction and deployment placement, but not yet that Payara successfully deployed and executed the application.

### Verify the running application

Run:

```bash
curl -sS 'http://localhost:8080/trace/api/info?name=runtime%20trace' | jq
```

This endpoint executes the servlet, uses `commons-lang3`, and builds its response through Jakarta JSON-P. A successful JSON response therefore provides runtime evidence that the WAR deployed and that the server supplied the Jakarta APIs that were deliberately absent from `WEB-INF/lib`.

### Observed

```json
{
  "message": "Hello Runtime trace",
  "application": "payara-mvnpm-trace-lab",
  "javaLibrary": "commons-lang3",
  "server": "Payara"
}
```

### Establish

The application is not merely present in the image: Payara successfully deployed and executed it. The servlet runs with `commons-lang3` from `WEB-INF/lib` while Jakarta JSON-P functionality is supplied by the server even though the Jakarta EE API JAR was deliberately omitted from the WAR.

## 9. Inspect the container image

### Why we need to do this

The application WAR is only part of the product that runs. The image also contains Payara, the JDK and operating-system packages. We now want to compare the software visible from the deployable WAR with the much larger inventory visible from the finished runtime image.

### How we're going to do it

Rather than hide the checks inside `image-trace.sh`, we will inspect the finished local image directly, one command at a time. First Syft will catalogue the complete image. We can then narrow the result to the tracer components and compare it with the WAR scan.

### Run

```bash
syft payara-mvnpm-trace-lab:local
```

### Observed

Syft catalogued:

```text
589 packages
825 executables
5,422 file-metadata locations
```

Relevant entries included:

```text
commons-lang3                  3.18.0       java-archive
payara-mvnpm-trace-lab        1.0.0        java-archive
jakarta.json-api              2.1.0        java-archive
jakarta.servlet-api           6.1.0        java-archive
zulu21-jre                    21.0.11-3    deb
```

The image inventory also contains a large set of Payara 7.2026.7 modules and Ubuntu packages. `lodash-es` was not reported as a package in the image scan.

### Establish

Crossing from the WAR to the finished container changes the inventory boundary dramatically:

```text
WAR scan
    2 packages
    commons-lang3 visible
    lodash-es not identifiable
    provided Jakarta APIs absent

container scan
    589 packages
    commons-lang3 visible
    application visible
    Jakarta APIs visible through Payara
    Payara + JDK + OS software visible
    lodash-es still not identifiable as a package
```

The same running application therefore has very different inventories depending on which artefact boundary is scanned. The container view recovers software supplied by the runtime, but it still cannot reconstruct the npm package identity lost when `lodash-es` was transformed into the browser bundle.

## Questions this project is designed to expose

- Does a normal Maven dependency tree include npm-origin code used by a Maven plugin?
- Does a Maven-generated application SBOM include that build-time mvnpm package?
- Can an artefact scanner recover `lodash-es` after esbuild has bundled it?
- Can we prove that `commons-lang3` is packaged while Jakarta EE APIs are server-provided?
- How much larger does the software inventory become when the WAR is placed inside Payara's container image?
- Does the final image scanner see Payara's own libraries as well as the application libraries?

## 10. Generate the Maven-model SBOM

### Why we need to do this

The WAR and container scans have shown us what a filesystem/artefact scanner can identify from built output. Now we need the other major SBOM viewpoint: an SBOM generated from Maven's project dependency model.

This matters because the three tracer components enter the build through different Maven mechanisms:

```text
commons-lang3
    normal project dependency

jakarta.jakartaee-web-api
    project dependency with provided scope

lodash-es
    dependency of the esbuild Maven plugin
```

A Maven-model SBOM may therefore describe a different software set from an artefact scan, even when both are emitted as CycloneDX.

### How we're going to do it

The CycloneDX Maven Plugin asks Maven to resolve the project's dependency model and writes the result as a CycloneDX JSON BOM. At this stage we are deliberately generating the BOM first and inspecting its contents separately rather than assuming what the plugin included from its component count.

### Run

```bash
mvn org.cyclonedx:cyclonedx-maven-plugin:2.9.3:makeBom \
  -DoutputFormat=json
```

### Observed

```text
CycloneDX: Resolving Dependencies
CycloneDX: Creating BOM version 1.6 with 27 component(s)
CycloneDX: Writing and validating BOM (JSON): target/bom.json
BUILD SUCCESS
```

### Establish

Maven successfully generated a CycloneDX 1.6 SBOM containing 27 components. The count alone does not tell us whether any of the three tracer dependencies are present, so the next step is to query the generated BOM directly.

### Inspect the tracer components

Run:

```bash
jq -r '.components[] | [.name, .version, (.scope // "-")] | @tsv' target/bom.json \
  | grep -E 'commons-lang3|jakarta.jakartaee-web-api|lodash-es'
```

This asks the BOM itself which of the three tracer identities survived into Maven's SBOM model.

### Observed

```text
jakarta.jakartaee-web-api    11.0.0    required
commons-lang3                 3.18.0    required
```

`lodash-es` is absent from the Maven-generated SBOM.

### Establish

The Maven-model SBOM follows the project's dependency model, not the physical contents of the final WAR.

```text
Maven project dependency model
    commons-lang3:3.18.0
        -> included in SBOM

    jakarta.jakartaee-web-api:11.0.0:provided
        -> included in SBOM as required

Maven plugin dependency model
    lodash-es:4.17.21
        -> absent from application SBOM
```

This gives us an important boundary distinction. The CycloneDX Maven Plugin sees a `provided` application dependency even though that dependency is deliberately absent from the WAR, while it does not include a dependency that belongs to the esbuild plugin even though code from that dependency demonstrably contributes to the shipped JavaScript.

The SBOM therefore describes Maven's application dependency model rather than a literal inventory of the bytes in the WAR.

## 11. Generate an artefact-derived SBOM from the WAR

### Why we need to do this

We now have a Maven-generated CycloneDX SBOM. To compare evidence sources fairly, we need a second CycloneDX SBOM generated from the built WAR itself.

This keeps the SBOM format constant while changing where the inventory comes from:

```text
same application
same CycloneDX format

Maven model -> SBOM
WAR bytes   -> SBOM
```

If the inventories differ, the difference cannot be explained by the SBOM standard. It comes from what evidence the generator can see.

### How we're going to do it

Syft will scan the completed WAR and emit its findings as CycloneDX JSON instead of its normal terminal table. We already know from the interactive scan that Syft can identify the WAR and `commons-lang3`, but cannot identify `lodash-es`.

### Run

```bash
mkdir -p trace-output

syft target/payara-mvnpm-trace-lab-1.0.0.war \
  -o cyclonedx-json=trace-output/war-syft.cdx.json
```

### Observed

```text
Packages [2 packages]
File digests [1 files]
File metadata [1 locations]
```

Syft successfully generated `trace-output/war-syft.cdx.json` from the physical WAR contents. The package count matches the earlier interactive WAR scan: two identifiable packages.

### Inspect the same tracer components

Run:

```bash
jq -r '.components[] | [.name, .version, (.scope // "-")] | @tsv' \
  trace-output/war-syft.cdx.json \
  | grep -E 'commons-lang3|jakarta.jakartaee-web-api|lodash-es|payara-mvnpm-trace-lab'
```

This repeats the tracer query against the artefact-derived CycloneDX BOM. Including the application name lets us see both components Syft believes are present in the WAR, while still testing for the provided Jakarta API and transformed lodash dependency.
