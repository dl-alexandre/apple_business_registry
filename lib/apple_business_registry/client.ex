defmodule AppleBusinessRegistry.Client do
  @moduledoc false

  alias AppleBusinessRegistry.{Business, Config, Error, Location, Token, TokenCache}

  @config_keys [
    :team_id,
    :key_id,
    :private_key,
    :private_key_path,
    :base_url,
    :token_ttl_seconds,
    :req_options
  ]

  @meta_keys [:decode, :params]

  @spec get(String.t(), keyword()) :: {:ok, term()} | {:error, term()}
  def get(path, opts) do
    {config_opts, meta, params} = split_opts(opts)
    config = Config.load(config_opts)

    with {:ok, access_token} <- fetch_access_token(config_opts) do
      req =
        Req.new(
          base_url: config.base_url,
          headers: [
            {"accept", "application/json"},
            {"content-type", "application/json"}
          ],
          auth: {:bearer, access_token}
        )
        |> Req.merge(config.req_options)

      query_params = Keyword.get(meta, :params, %{})
      merged_params = Map.merge(query_params, Map.new(params))

      req
      |> Req.get(url: path, params: merged_params)
      |> normalize(meta)
    end
  end

  @spec post(String.t(), map(), keyword()) :: {:ok, term()} | {:error, term()}
  def post(path, body, opts) do
    {config_opts, meta, _params} = split_opts(opts)
    config = Config.load(config_opts)

    with {:ok, access_token} <- fetch_access_token(config_opts) do
      req =
        Req.new(
          base_url: config.base_url,
          headers: [
            {"accept", "application/json"},
            {"content-type", "application/json"}
          ],
          auth: {:bearer, access_token}
        )
        |> Req.merge(config.req_options)

      req
      |> Req.post(url: path, json: body)
      |> normalize(meta)
    end
  end

  @spec patch(String.t(), map(), keyword()) :: {:ok, term()} | {:error, term()}
  def patch(path, body, opts) do
    {config_opts, meta, _params} = split_opts(opts)
    config = Config.load(config_opts)

    with {:ok, access_token} <- fetch_access_token(config_opts) do
      req =
        Req.new(
          base_url: config.base_url,
          headers: [
            {"accept", "application/json"},
            {"content-type", "application/json"}
          ],
          auth: {:bearer, access_token}
        )
        |> Req.merge(config.req_options)

      req
      |> Req.patch(url: path, json: body)
      |> normalize(meta)
    end
  end

  @spec delete(String.t(), keyword()) :: :ok | {:error, term()}
  def delete(path, opts) do
    {config_opts, _meta, _params} = split_opts(opts)
    config = Config.load(config_opts)

    with {:ok, access_token} <- fetch_access_token(config_opts) do
      req =
        Req.new(
          base_url: config.base_url,
          headers: [
            {"accept", "application/json"},
            {"content-type", "application/json"}
          ],
          auth: {:bearer, access_token}
        )
        |> Req.merge(config.req_options)

      case Req.delete(req, url: path) do
        {:ok, %Req.Response{status: status}} when status in 200..299 ->
          :ok

        {:ok, %Req.Response{status: status, body: body}} ->
          {:error, Error.from_http(status, body)}

        {:error, reason} ->
          {:error, {:transport_error, reason}}
      end
    end
  end

  defp fetch_access_token([]), do: TokenCache.fetch()
  defp fetch_access_token(config_opts), do: Token.access_token(config_opts)

  defp split_opts(opts) do
    {config, rest} = Keyword.split(opts, @config_keys)
    {meta, params} = Keyword.split(rest, @meta_keys)
    {config, meta, params}
  end

  defp normalize({:ok, %Req.Response{status: status, body: body}}, meta)
       when status in 200..299 do
    if Keyword.get(meta, :decode, false) do
      {:ok, decode_body(body)}
    else
      {:ok, body}
    end
  end

  defp normalize({:ok, %Req.Response{status: status, body: body}}, _meta),
    do: {:error, Error.from_http(status, body)}

  defp normalize({:error, reason}, _meta),
    do: {:error, {:transport_error, reason}}

  defp decode_body(body) when is_map(body) do
    cond do
      Map.has_key?(body, "results") && is_list(body["results"]) ->
        %{body | "results" => decode_results(body["results"])}

      Map.has_key?(body, "id") && Map.has_key?(body, "name") ->
        if Map.has_key?(body, "address") do
          Location.from_map(body)
        else
          Business.from_map(body)
        end

      true ->
        body
    end
  end

  defp decode_body(body), do: body

  defp decode_results(results) do
    Enum.map(results, fn item ->
      cond do
        Map.has_key?(item, "address") -> Location.from_map(item)
        Map.has_key?(item, "organizationType") -> Business.from_map(item)
        true -> item
      end
    end)
  end
end
