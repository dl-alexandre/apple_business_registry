defmodule AppleBusinessRegistry.Token do
  @moduledoc """
  Apple Business Registry token generation and exchange.

  Apple's flow has two steps:

    1. Sign an ES256 JWT with your Business Registry private key (`.p8`), identifying the
       Business key via the `kid` header and your Team ID via the `iss` claim.
    2. Exchange that JWT for a short-lived **access token** at `POST /v1/token/oauth2`.
       That access token is what every subsequent API call must send as its
       `Authorization: Bearer` credential.

  `generate_jwt/1` does step 1; `access_token/1` does both.
  """

  alias AppleBusinessRegistry.{Config, Error}

  @type jwt :: String.t()

  @doc "Build and sign the Apple Business Registry auth JWT (ES256)."
  @spec generate_jwt(keyword()) :: {:ok, jwt} | {:error, term()}
  def generate_jwt(opts \\ []) do
    config = Config.load(opts)
    now = System.system_time(:second)

    with {:ok, team_id} <- require_field(config.team_id, :team_id),
         {:ok, key_id} <- require_field(config.key_id, :key_id) do
      claims = %{
        "iss" => team_id,
        "iat" => now,
        "exp" => now + config.token_ttl_seconds
      }

      header = %{
        "alg" => "ES256",
        "kid" => key_id,
        "typ" => "JWT"
      }

      try do
        jwk = Config.private_key_pem!(config) |> JOSE.JWK.from_pem()
        {_, compact} = JOSE.JWT.sign(jwk, header, claims) |> JOSE.JWS.compact()
        {:ok, compact}
      rescue
        e -> {:error, {:token_generation_failed, Exception.message(e)}}
      end
    end
  end

  @doc "Sign a JWT and exchange it for an Apple Business Registry **access token**."
  @spec access_token(keyword()) :: {:ok, String.t()} | {:error, term()}
  def access_token(opts \\ []) do
    with {:ok, token, _expires_at} <- access_token_with_expiry(opts), do: {:ok, token}
  end

  @doc """
  Like `access_token/1` but also returns the unix-epoch expiry time, for cache use.
  """
  @spec access_token_with_expiry(keyword()) ::
          {:ok, String.t(), integer()} | {:error, term()}
  def access_token_with_expiry(opts \\ []) do
    config = Config.load(opts)

    with {:ok, jwt} <- generate_jwt(opts) do
      req =
        Req.new(
          base_url: config.base_url,
          headers: [
            {"accept", "application/json"},
            {"content-type", "application/x-www-form-urlencoded"}
          ]
        )
        |> Req.merge(config.req_options)

      body =
        URI.encode_query(%{
          "grant_type" => "client_credentials",
          "client_assertion_type" => "urn:ietf:params:oauth:client-assertion-type:jwt-bearer",
          "client_assertion" => jwt,
          "scope" => "business_registry"
        })

      case Req.post(req, url: "/v1/token/oauth2", body: body) do
        {:ok, %Req.Response{status: 200, body: %{"access_token" => token} = body}} ->
          ttl = Map.get(body, "expires_in", 1800)
          {:ok, token, System.system_time(:second) + ttl}

        {:ok, %Req.Response{status: status, body: body}} ->
          {:error, Error.from_http(status, body)}

        {:error, reason} ->
          {:error, {:transport_error, reason}}
      end
    end
  end

  defp require_field(nil, name), do: {:error, {:missing_config, name}}
  defp require_field("", name), do: {:error, {:missing_config, name}}
  defp require_field(value, _), do: {:ok, value}
end
