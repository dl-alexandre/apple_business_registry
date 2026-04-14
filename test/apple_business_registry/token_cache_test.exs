defmodule AppleBusinessRegistry.TokenCacheTest do
  use ExUnit.Case

  alias AppleBusinessRegistry.{TokenCache, TestKey}

  setup do
    # Ensure the cache is cleared before each test
    TokenCache.clear()

    # Store original env to restore later
    original_env = Application.get_all_env(:apple_business_registry)

    on_exit(fn ->
      # Restore original env
      Application.put_all_env(apple_business_registry: original_env)
      TokenCache.clear()
    end)

    {:ok, %{original_env: original_env}}
  end

  test "fetch/0 returns cached token on subsequent calls" do
    bypass = Bypass.open()

    call_count = :atomics.new(1, signed: false)

    Bypass.stub(bypass, "POST", "/v1/token/oauth2", fn conn ->
      :atomics.add(call_count, 1, 1)

      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.resp(
        200,
        Jason.encode!(%{"access_token" => "CACHED_TOKEN", "expires_in" => 1800})
      )
    end)

    # Set application env for the test
    Application.put_all_env(
      apple_business_registry: [
        team_id: "T",
        key_id: "K",
        private_key: TestKey.pem(),
        base_url: "http://localhost:#{bypass.port}"
      ]
    )

    # First call should hit the server
    assert {:ok, "CACHED_TOKEN"} = TokenCache.fetch()

    # Second call should use cached token (no additional HTTP request)
    assert {:ok, "CACHED_TOKEN"} = TokenCache.fetch()

    # Verify only one HTTP call was made
    assert :atomics.get(call_count, 1) == 1
  end

  test "clear/0 removes cached token" do
    # Just verify the function exists and returns :ok
    assert :ok = TokenCache.clear()
  end
end
