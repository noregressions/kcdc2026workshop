---
id: setup-accounts-and-keys
oneliner: "Snyk authentication and the NVD API key: the two credentials some investigations need."
track: core
---

# Accounts and Keys

A small number of investigations need authentication or API access; set
these up before the workshop.

## Snyk

T01 requires an authenticated Snyk CLI. **A free Snyk account is
sufficient**: nothing in this workshop needs a paid tier.

```bash
snyk auth
```

Verify:

```bash
snyk --version
snyk config get api
```

Do not commit Snyk credentials to the repository.

---

# NVD API key for T06

T06 uses the OWASP Dependency-Check Maven Plugin.

The harness behaves as follows:

```text
NVD_API_KEY present
    -> Dependency-Check 13.0.0

NVD_API_KEY absent
    -> Dependency-Check 12.2.2
```

This is deliberate because Dependency-Check 13.0.0 has a known no-key regression in the NVD update path.

For the exact T06 run used to produce the workshop evidence, use a valid NVD API key.

## Request an NVD API key

Go to:

```text
https://nvd.nist.gov/developers/request-an-api-key
```

The form asks for:

```text
organisation name
email address
organisation type
```

Then:

```text
1. Accept the NVD Terms of Use.
2. Submit the request.
3. Check your email for the activation message.
4. Open the activation link.
5. Activate the key.
6. Copy the key into a secure secret store.
```

The activation link is single-use and expires after seven days.

Do not commit the NVD API key to the repository.

## Export the key

```bash
export NVD_API_KEY='your-key-here'
```

Verify that it is exported:

```bash
printenv NVD_API_KEY >/dev/null &&
  echo "NVD_API_KEY is exported"
```

The T06 harness should then print:

```text
NVD API key: supplied via NVD_API_KEY environment variable
```

If it prints:

```text
NVD API key: not supplied
```

then the variable is either unset or not exported into the shell running the script.

---

# Docker account

Docker Scout may require Docker authentication in some environments.

Before the workshop:

```bash
docker login
```

Verify:

```bash
docker scout version
```

T02 requires Docker Scout, which Podman does not provide.

---

# npm registry access

T07 uses:

```text
https://registry.npmjs.org/
```

You do not need a special npm account for the audit experiment, but your machine must be able to reach the public npm registry.

Check:

```bash
npm config get registry
```

Expected:

```text
https://registry.npmjs.org/
```

---

# Network access

The workshop may need outbound access to:

```text
repo.maven.apache.org
registry.npmjs.org
registry-1.docker.io
api.snyk.io
nvd.nist.gov
cisa.gov
github.com
api.github.com
raw.githubusercontent.com
pypi.org
```

Corporate proxies, VPNs and TLS interception can interfere with Maven, npm, Docker pulls and scanner database downloads.

If you are using a managed laptop, test the pre-warm steps in [`04 PREPULL-PREWARM.md`](./04%20PREPULL-PREWARM.md) before arriving at the workshop.
