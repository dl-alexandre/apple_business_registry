defmodule AppleBusinessRegistry.TokenTest do
  use ExUnit.Case, async: true

  alias AppleBusinessRegistry.{TestKey, Token}

  setup do
    %{pem: TestKey.pem()}
  end

  test "generate_jwt/1 signs an ES256 JWT with required header and claims", %{pem: pem} do
    {:ok, jwt} =
      Token.generate_jwt(
        team_id: "TEAM123",
        key_id: "KEY456",
        private_key: pem,
        token_ttl_seconds: 120
      )

    [header_b64, payload_b64, _sig] = String.split(jwt, ".")
    header = header_b64 |> Base.url_decode64!(padding: false) |> Jason.decode!()
    payload = payload_b64 |> Base.url_decode64!(padding: false) |> Jason.decode!()

    assert header["alg"] == "ES256"
    assert header["kid"] == "KEY456"
    assert header["typ"] == "JWT"

    assert payload["iss"] == "TEAM123"
    assert is_integer(payload["iat"])
    assert payload["exp"] - payload["iat"] == 120
  end

  test "generate_jwt/1 reports missing team_id", %{pem: pem} do
    assert {:error, {:missing_config, :team_id}} =
             Token.generate_jwt(key_id: "K", private_key: pem)
  end

  test "generate_jwt/1 reports missing key_id", %{pem: pem} do
    assert {:error, {:missing_config, :key_id}} =
             Token.generate_jwt(team_id: "T", private_key: pem)
  end

  test "generate_jwt/1 returns error tuple for malformed PEM" do
    assert {:error, {:token_generation_failed, _}} =
             Token.generate_jwt(team_id: "T", key_id: "K", private_key: "not a pem")
  end

  test "generate_jwt/1 returns error tuple for missing key file" do
    assert {:error, {:token_generation_failed, _}} =
             Token.generate_jwt(
               team_id: "T",
               key_id: "K",
               private_key: nil,
               private_key_path: "/nonexistent/key.p8"
             )
  end

  test "access_token/1 exchanges JWT for access token", %{pem: pem} do
    bypass = Bypass.open()

    Bypass.expect_once(bypass, "POST", "/v1/token/oauth2", fn conn ->
      {:ok, body, conn} = Plug.Conn.read_body(conn)
      params = URI.decode_query(body)

      assert params["grant_type"] == "client_credentials"

      assert params["client_assertion_type"] ==
               "urn:ietf:params:oauth:client-assertion-type:jwt-bearer"

      assert params["scope"] == "business_registry"

      jwt = params["client_assertion"]
      assert String.split(jwt, ".") |> length() == 3

      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.resp(
        200,
        Jason.encode!(%{"access_token" => "ACCESS_123", "expires_in" => 1800})
      )
    end)

    assert {:ok, "ACCESS_123"} =
             Token.access_token(
               team_id: "T",
               key_id: "K",
               private_key: pem,
               base_url: "http://localhost:#{bypass.port}"
             )
  end

  test "access_token/1 surfaces 401 as Error struct", %{pem: pem} do
    bypass = Bypass.open()

    Bypass.expect_once(bypass, "POST", "/v1/token/oauth2", fn conn ->
      Plug.Conn.resp(conn, 401, Jason.encode!(%{"error" => "invalid_client"}))
    end)

    assert {:error, %AppleBusinessRegistry.Error{status: 401}} =
             Token.access_token(
               team_id: "T",
               key_id: "K",
               private_key: pem,
               base_url: "http://localhost:#{bypass.port}"
             )
  end
end
