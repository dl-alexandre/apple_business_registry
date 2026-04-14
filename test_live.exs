#!/usr/bin/env elixir

Mix.install([
  {:apple_business_registry, path: "."},
  {:dotenv, "~> 3.0"}
])

Dotenv.load()

defmodule AppleBusinessRegistryLiveTest do
  def run do
    IO.puts("=" <> String.duplicate("=", 70))
    IO.puts("APPLE BUSINESS REGISTRY LIVE TEST")
    IO.puts("=" <> String.duplicate("=", 70))
    IO.puts("")

    configure_from_env()

    {:ok, _} = Application.ensure_all_started(:apple_business_registry)
    IO.puts("✅ Apple Business Registry application started")
    IO.puts("")

    IO.puts("Configuration:")
    IO.puts("  Team ID: #{System.get_env("APPLE_TEAM_ID") || "NOT SET"}")
    IO.puts("  Key ID: #{System.get_env("BUSINESS_REGISTRY_KEY_ID") || "NOT SET"}")
    IO.puts("  Key File: #{System.get_env("BUSINESS_REGISTRY_PRIVATE_KEY_PATH") || "NOT SET"}")

    IO.puts("")
    IO.puts("► Test 1: Access Token Generation")
    IO.puts(String.duplicate("-", 50))

    case AppleBusinessRegistry.token() do
      {:ok, token} ->
        IO.puts("✅ Access token generated successfully")
        IO.puts("   Length: #{String.length(token)} characters")
        IO.puts("   Preview: #{String.slice(token, 0, 50)}...")
        IO.puts("")
        maybe_run_api_test()

      {:error, reason} ->
        IO.puts("❌ Access token generation failed")
        IO.puts("   Reason: #{inspect(reason)}")
    end

    IO.puts("")
    IO.puts("=" <> String.duplicate("=", 70))
    IO.puts("Test complete")
    IO.puts("=" <> String.duplicate("=", 70))
  end

  defp configure_from_env do
    Application.put_env(:apple_business_registry, :team_id, System.get_env("APPLE_TEAM_ID"))

    Application.put_env(
      :apple_business_registry,
      :key_id,
      System.get_env("BUSINESS_REGISTRY_KEY_ID")
    )

    Application.put_env(
      :apple_business_registry,
      :private_key_path,
      System.get_env("BUSINESS_REGISTRY_PRIVATE_KEY_PATH")
    )

    maybe_put_env(:base_url, "BUSINESS_REGISTRY_BASE_URL")

    case System.get_env("BUSINESS_REGISTRY_TOKEN_TTL_SECONDS") do
      nil ->
        :ok

      ttl ->
        Application.put_env(:apple_business_registry, :token_ttl_seconds, String.to_integer(ttl))
    end
  end

  defp maybe_put_env(app_key, env_key) do
    case System.get_env(env_key) do
      nil -> :ok
      value -> Application.put_env(:apple_business_registry, app_key, value)
    end
  end

  defp maybe_run_api_test do
    if System.get_env("APPLE_BUSINESS_REGISTRY_RUN_API", "false") == "true" do
      IO.puts("► Test 2: List Businesses")
      IO.puts(String.duplicate("-", 50))

      case AppleBusinessRegistry.list_businesses() do
        {:ok, body} ->
          IO.puts("✅ Business Registry API call succeeded")
          IO.puts("   Response preview: #{inspect(body) |> String.slice(0, 200)}")

        {:error, %AppleBusinessRegistry.Error{} = error} ->
          IO.puts("❌ Business Registry API call failed")
          IO.puts("   Status: #{error.status}")
          IO.puts("   Message: #{error.message}")
          IO.puts("   Details: #{inspect(error.details)}")

        {:error, reason} ->
          IO.puts("❌ Business Registry API call failed")
          IO.puts("   Reason: #{inspect(reason)}")
      end
    else
      IO.puts("► Test 2: Business Registry API Call")
      IO.puts(String.duplicate("-", 50))
      IO.puts("⏭️  Skipped: set APPLE_BUSINESS_REGISTRY_RUN_API=true in .env to call Apple")
    end
  end
end

AppleBusinessRegistryLiveTest.run()
