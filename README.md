# AppleBusinessRegistry

Elixir client for Apple Business Registry / Apple Business Connect-style business and location management APIs.

## Status

This package is currently **experimental**.

The Elixir client surface and tests are in place, but Apple’s current Business Connect API onboarding appears to use Business Connect service accounts (`client_id` and `client_secret`) rather than the older developer-key-style JWT flow this package currently implements.

Because of that mismatch, treat this package as a draft until the auth layer is refactored to Apple’s current service-account model.

## Current Surface

The implemented API includes:

- business CRUD
- location CRUD
- search
- validation helpers
- struct decoding for businesses and locations

## Installation

```elixir
defp deps do
  [
    {:apple_business_registry, "~> 0.3.0"}
  ]
end
```

## What Works Today

- package compiles
- test suite passes
- top-level public API is documented in `lib/apple_business_registry.ex`
- `test_live.exs` exists for the eventual live auth path

## Publishing Note

If you publish this package before the auth refactor, it should be clearly marked as preview or experimental.

## License

MIT
