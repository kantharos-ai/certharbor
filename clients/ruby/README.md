# certharbor-client (Ruby)

Typed Ruby client generated from `backend/openapi/openapi.json` with
[OpenAPI Generator](https://openapi-generator.tech) (`ruby` target), mirroring
the TypeScript client at `clients/ts` -- see `docs/plans/frontend-backend-split.md`
sections D4 (generator choice) and D8 (versioning, consumption, publication).

## What's committed vs. generated

Only hand-written packaging files are committed: `certharbor-client.gemspec`,
`Gemfile`, `Rakefile`, `.openapi-generator-ignore`, `README.md`, and this
directory's `spec/smoke_spec.rb`. Everything OpenAPI Generator produces
(`lib/`, `docs/`, its own `spec/api/*_spec.rb` and `spec/spec_helper.rb`) is
gitignored and rebuilt by `rake generate`. Never hand-edit generated files;
the next `rake generate` silently overwrites them.

## Usage

```bash
bundle install
rake generate   # regenerates lib/ from ../../backend/openapi/openapi.json
rake build      # generate + `gem build`, produces certharbor-client-<version>.gem
rake spec       # generator's own rspec suite + this gem's smoke test
```

Generation requires a JVM (OpenAPI Generator is a Java tool even though it
emits Ruby). `rake generate` downloads `openapi-generator-cli.jar` from Maven
Central into a local cache (`.cache/`, gitignored) the first time it runs, so
no Node toolchain and no Docker are required -- the same jar-plus-`java`
invocation runs identically on devel and in CI.

## Versioning

`<VERSION>-sha.<short-sha>`, via `../../scripts/client-version.sh` -- the
same scheme and script the TypeScript client uses (D8).

## Publication

Published to GitHub Packages' RubyGems registry
(`https://rubygems.pkg.github.com/kantharos-ai`) only on `v*` tags, same
cadence as the TypeScript client, to avoid republish-collision churn on every
merge. See `.github/workflows/client-ruby.yml`.
