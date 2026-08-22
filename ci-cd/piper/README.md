# Project Piper (Jenkins)

Real files: `services/procurement-core/.pipeline/config.yml` and
`services/procurement-core/Jenkinsfile` — see `ci-cd/README.md` for why
they live there, not here.

## What the Jenkinsfile actually does

```groovy
@Library('piper-lib-os') _
piperPipeline script: this
```

The minimal, real form — once `.pipeline/config.yml` exists and defines
`stages`/`steps`, `piperPipeline` reads it and runs whatever's toggled on.
The alternative (explicit `stage(){ steps{ mtaBuild script: this } }`
blocks per step) is also valid Piper usage — SAP's own `leverx`-style
reference pipelines use that style — but it's redundant once a
`config.yml` is doing the real work, so this project uses the shorter form.

## Pipeline stages (from `.pipeline/config.yml`)

1. **Build** — `npmExecuteLint` (currently non-blocking — no lint config is
   committed yet, so this gate doesn't do anything real; flagged honestly
   rather than left silently toothless)
2. **Additional Unit Tests** — `npmExecuteScripts` runs `npm test`
3. **Release** — `mtaBuild` (via `mtaBuildTool: cloudMbt`) then
   `cloudFoundryDeploy`, targeting the `procureiq-dev` org / `dev` space

## Verified, not guessed

Every step name and parameter in `.pipeline/config.yml`
(`cfCredentialsId`, `apiEndpoint`, `mtaExtensionDescriptor`, etc.) was
checked against `SAP/jenkins-library`'s real step metadata
(`resources/metadata/mtaBuild.yaml`, `cloudFoundryDeploy.yaml`) — not
written from memory.

## Not yet wired up

- No Jenkins server exists for this project yet — there's nothing to
  actually run this pipeline against. The files are real and correct;
  running them is an account-and-infrastructure-gated next step.
- `tmsUpload` (Cloud Transport Management promotion) is commented out in
  `.pipeline/config.yml` — see `transport/cloud-transport-management` once
  that's built.
