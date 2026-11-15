#!/usr/bin/env ruby
# frozen_string_literal: true

# Post-generate fixup, run by `rake generate` right after the openapi-generator
# invocation -- same role as clients/ts/scripts/fix-esm-extensions.mjs plays
# for the TS client's generator quirks.
#
# Known openapi-generator bug (ruby target, generator 7.17.0, OAS 3.1):
# certharbor's `session` security scheme is a cookie-based apiKey
# (`in: cookie`, see backend/openapi/openapi.json#/components/securitySchemes/session,
# required by D6). The ruby generator's Configuration#auth_settings template
# has no case for `in: cookie` and emits a literally invalid hash entry,
# `in: ,` with no value -- lib/certharbor-client/configuration.rb fails at
# runtime with `NoMethodError: undefined method 'in'`. Separately,
# ApiClient#update_params_for_auth! only understands `header` and `query`
# locations and raises ArgumentError for anything else, so even a
# syntactically valid `in: 'cookie'` would still not send the cookie.
#
# Neither half is configurable via openapi-generator's ruby options as of
# 7.17.0; this is a generator gap, not a certharbor spec issue. The fix below
# patches both generated files post-generation so the session cookie is
# actually sent as a `Cookie` header, and is idempotent so re-running
# `rake generate` after an upstream generator fix is a harmless no-op (the
# patterns simply won't match anymore).
root = File.expand_path('..', __dir__)

config_path = File.join(root, 'lib/certharbor-client/configuration.rb')
config = File.read(config_path)
fixed_config = config.sub(/in:\s*,/, "in: 'cookie',")
if fixed_config != config
  File.write(config_path, fixed_config)
  puts "fix_cookie_auth: patched #{config_path} (in: , -> in: 'cookie',)"
end

client_path = File.join(root, 'lib/certharbor-client/api_client.rb')
client = File.read(client_path)
fixed_client = client.sub(
  /when 'query'  then query_params\[auth_setting\[:key\]\] = auth_setting\[:value\]\n(\s*)else fail/,
  "when 'query'  then query_params[auth_setting[:key]] = auth_setting[:value]\n" \
  "        when 'cookie' then header_params['Cookie'] = [header_params['Cookie'], " \
  "\"\#{auth_setting[:key]}=\#{auth_setting[:value]}\"].compact.join('; ')\n" \
  "\\1else fail"
)
if fixed_client != client
  File.write(client_path, fixed_client)
  puts "fix_cookie_auth: patched #{client_path} (added 'cookie' auth location)"
end
