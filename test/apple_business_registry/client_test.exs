defmodule AppleBusinessRegistry.ClientTest do
  use ExUnit.Case, async: true

  alias AppleBusinessRegistry.{Client, Error, TestKey}

  setup do
    bypass = Bypass.open()

    opts = [
      team_id: "T",
      key_id: "K",
      private_key: TestKey.pem(),
      base_url: "http://localhost:#{bypass.port}"
    ]

    %{bypass: bypass, opts: opts}
  end

  defp stub_token(bypass) do
    Bypass.stub(bypass, "POST", "/v1/token/oauth2", fn conn ->
      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.resp(200, Jason.encode!(%{"access_token" => "ACCESS", "expires_in" => 1800}))
    end)
  end

  test "get/2 sends access token and returns body", %{bypass: bypass, opts: opts} do
    stub_token(bypass)

    Bypass.expect_once(bypass, "GET", "/v1/businesses", fn conn ->
      assert ["Bearer ACCESS"] = Plug.Conn.get_req_header(conn, "authorization")

      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.resp(200, Jason.encode!(%{"results" => []}))
    end)

    assert {:ok, %{"results" => []}} = Client.get("/v1/businesses", opts)
  end

  test "get/2 maps non-2xx to Error struct", %{bypass: bypass, opts: opts} do
    stub_token(bypass)

    Bypass.expect_once(bypass, "GET", "/v1/businesses/biz_123", fn conn ->
      Plug.Conn.resp(conn, 404, Jason.encode!(%{"error" => "not_found"}))
    end)

    assert {:error, %Error{status: 404}} =
             Client.get("/v1/businesses/biz_123", opts)
  end

  test "post/3 creates resource and returns body", %{bypass: bypass, opts: opts} do
    stub_token(bypass)

    Bypass.expect_once(bypass, "POST", "/v1/businesses", fn conn ->
      assert ["Bearer ACCESS"] = Plug.Conn.get_req_header(conn, "authorization")

      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.resp(201, Jason.encode!(%{"id" => "biz_123", "name" => "Acme Inc"}))
    end)

    assert {:ok, %{"id" => "biz_123", "name" => "Acme Inc"}} =
             Client.post("/v1/businesses", %{"name" => "Acme Inc"}, opts)
  end

  test "patch/3 updates resource and returns body", %{bypass: bypass, opts: opts} do
    stub_token(bypass)

    Bypass.expect_once(bypass, "PATCH", "/v1/businesses/biz_123", fn conn ->
      assert ["Bearer ACCESS"] = Plug.Conn.get_req_header(conn, "authorization")

      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.resp(200, Jason.encode!(%{"id" => "biz_123", "name" => "Acme Corp"}))
    end)

    assert {:ok, %{"id" => "biz_123", "name" => "Acme Corp"}} =
             Client.patch("/v1/businesses/biz_123", %{"name" => "Acme Corp"}, opts)
  end

  test "delete/2 removes resource and returns :ok", %{bypass: bypass, opts: opts} do
    stub_token(bypass)

    Bypass.expect_once(bypass, "DELETE", "/v1/businesses/biz_123", fn conn ->
      assert ["Bearer ACCESS"] = Plug.Conn.get_req_header(conn, "authorization")

      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.resp(204, "")
    end)

    assert :ok = Client.delete("/v1/businesses/biz_123", opts)
  end

  test "get/2 with decode: true returns Business struct for business data", %{
    bypass: bypass,
    opts: opts
  } do
    stub_token(bypass)

    Bypass.expect_once(bypass, "GET", "/v1/businesses/biz_123", fn conn ->
      body = %{
        "id" => "biz_123",
        "name" => "Acme Inc",
        "organizationType" => "company"
      }

      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.resp(200, Jason.encode!(body))
    end)

    assert {:ok, %AppleBusinessRegistry.Business{id: "biz_123", name: "Acme Inc"}} =
             Client.get("/v1/businesses/biz_123", Keyword.put(opts, :decode, true))
  end

  test "get/2 with decode: true returns Location struct for location data", %{
    bypass: bypass,
    opts: opts
  } do
    stub_token(bypass)

    Bypass.expect_once(bypass, "GET", "/v1/businesses/biz_123/locations/loc_456", fn conn ->
      body = %{
        "id" => "loc_456",
        "businessId" => "biz_123",
        "name" => "Main Store",
        "address" => "1 Infinite Loop"
      }

      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.resp(200, Jason.encode!(body))
    end)

    assert {:ok, %AppleBusinessRegistry.Location{id: "loc_456", name: "Main Store"}} =
             Client.get(
               "/v1/businesses/biz_123/locations/loc_456",
               Keyword.put(opts, :decode, true)
             )
  end

  test "get/2 maps transport failure", %{bypass: bypass, opts: opts} do
    stub_token(bypass)
    Bypass.down(bypass)

    no_retry = Keyword.put(opts, :req_options, retry: false)

    assert {:error, _reason} =
             Client.get("/v1/businesses", no_retry)
  end
end
