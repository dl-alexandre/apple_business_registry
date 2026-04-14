defmodule AppleBusinessRegistry do
  @moduledoc """
  Elixir client for the [Apple Business Registry API](https://developer.apple.com/documentation/businessregistryapi).

  The public surface is intentionally small:

      AppleBusinessRegistry.list_businesses()
      AppleBusinessRegistry.get_business("business_id")
      AppleBusinessRegistry.create_business(%{name: "Acme Inc", ...})
      AppleBusinessRegistry.update_business("business_id", %{name: "Acme Corp", ...})
      AppleBusinessRegistry.delete_business("business_id")
      AppleBusinessRegistry.list_locations("business_id")
      AppleBusinessRegistry.get_location("business_id", "location_id")
      AppleBusinessRegistry.token()

  ## Configuration

      config :apple_business_registry,
        team_id: System.get_env("APPLE_TEAM_ID"),
        key_id: System.get_env("BUSINESS_REGISTRY_KEY_ID"),
        private_key: System.get_env("BUSINESS_REGISTRY_PRIVATE_KEY"),
        base_url: "https://businessregistry.apple.com",
        token_ttl_seconds: 300

  Every function also accepts per-call `opts` that override the application config.
  """

  alias AppleBusinessRegistry.{Client, Token}

  @type opts :: keyword()
  @type response :: {:ok, map()} | {:error, term()}

  @doc "Return a cached-per-call Apple Business Registry **access token** (after the JWT → token exchange)."
  @spec token(opts) :: {:ok, String.t()} | {:error, term()}
  def token(opts \\ []), do: Token.access_token(opts)

  @doc """
  List all businesses registered to your team.

  Returns a list of business maps. Use `decode: true` to get `Business` structs.
  """
  @spec list_businesses(opts) :: {:ok, list(map())} | {:error, term()}
  def list_businesses(opts \\ []) do
    Client.get("/v1/businesses", opts)
  end

  @doc """
  Get details for a specific business.

  ## Parameters

    - `business_id`: The unique identifier of the business
  """
  @spec get_business(String.t(), opts) :: response
  def get_business(business_id, opts \\ []) when is_binary(business_id) do
    Client.get("/v1/businesses/#{business_id}", opts)
  end

  @doc """
  Create a new business registration.

  ## Parameters

    - `attrs`: Map of business attributes including:
      - `name` (required): Business name
      - `organization_type`: Organization type (e.g., "company", "nonprofit")
      - `primary_phone`: Primary contact phone number
      - `primary_email`: Primary contact email
      - `website`: Business website URL
      - `description`: Business description

  ## Examples

      AppleBusinessRegistry.create_business(%{
        name: "Acme Inc",
        organization_type: "company",
        primary_phone: "+1-555-123-4567",
        primary_email: "contact@acme.com"
      })
  """
  @spec create_business(map(), opts) :: response
  def create_business(attrs, opts \\ []) when is_map(attrs) do
    Client.post("/v1/businesses", attrs, opts)
  end

  @doc """
  Update an existing business registration.

  ## Parameters

    - `business_id`: The unique identifier of the business
    - `attrs`: Map of business attributes to update
  """
  @spec update_business(String.t(), map(), opts) :: response
  def update_business(business_id, attrs, opts \\ [])
      when is_binary(business_id) and is_map(attrs) do
    Client.patch("/v1/businesses/#{business_id}", attrs, opts)
  end

  @doc """
  Delete a business registration.

  ## Parameters

    - `business_id`: The unique identifier of the business to delete
  """
  @spec delete_business(String.t(), opts) :: :ok | {:error, term()}
  def delete_business(business_id, opts \\ []) when is_binary(business_id) do
    Client.delete("/v1/businesses/#{business_id}", opts)
  end

  @doc """
  List all locations for a business.

  ## Parameters

    - `business_id`: The unique identifier of the business

  Returns a list of location maps. Use `decode: true` to get `Location` structs.
  """
  @spec list_locations(String.t(), opts) :: {:ok, list(map())} | {:error, term()}
  def list_locations(business_id, opts \\ []) when is_binary(business_id) do
    Client.get("/v1/businesses/#{business_id}/locations", opts)
  end

  @doc """
  Get details for a specific location.

  ## Parameters

    - `business_id`: The unique identifier of the business
    - `location_id`: The unique identifier of the location
  """
  @spec get_location(String.t(), String.t(), opts) :: response
  def get_location(business_id, location_id, opts \\ [])
      when is_binary(business_id) and is_binary(location_id) do
    Client.get("/v1/businesses/#{business_id}/locations/#{location_id}", opts)
  end

  @doc """
  Create a new location for a business.

  ## Parameters

    - `business_id`: The unique identifier of the business
    - `attrs`: Map of location attributes including:
      - `name` (required): Location name
      - `address` (required): Street address
      - `locality`: City/locality
      - `administrative_area`: State/province
      - `postal_code`: Postal code
      - `country`: ISO country code
      - `phone`: Location phone number
      - `latitude`: Latitude coordinate
      - `longitude`: Longitude coordinate

  ## Examples

      AppleBusinessRegistry.create_location("biz_123", %{
        name: "Acme HQ",
        address: "1 Infinite Loop",
        locality: "Cupertino",
        administrative_area: "CA",
        postal_code: "95014",
        country: "US",
        latitude: 37.3318,
        longitude: -122.0312
      })
  """
  @spec create_location(String.t(), map(), opts) :: response
  def create_location(business_id, attrs, opts \\ [])
      when is_binary(business_id) and is_map(attrs) do
    Client.post("/v1/businesses/#{business_id}/locations", attrs, opts)
  end

  @doc """
  Update an existing location.

  ## Parameters

    - `business_id`: The unique identifier of the business
    - `location_id`: The unique identifier of the location
    - `attrs`: Map of location attributes to update
  """
  @spec update_location(String.t(), String.t(), map(), opts) :: response
  def update_location(business_id, location_id, attrs, opts \\ [])
      when is_binary(business_id) and is_binary(location_id) and is_map(attrs) do
    Client.patch("/v1/businesses/#{business_id}/locations/#{location_id}", attrs, opts)
  end

  @doc """
  Delete a location.

  ## Parameters

    - `business_id`: The unique identifier of the business
    - `location_id`: The unique identifier of the location to delete
  """
  @spec delete_location(String.t(), String.t(), opts) :: :ok | {:error, term()}
  def delete_location(business_id, location_id, opts \\ [])
      when is_binary(business_id) and is_binary(location_id) do
    Client.delete("/v1/businesses/#{business_id}/locations/#{location_id}", opts)
  end

  @doc """
  Search for businesses by name, phone, or other criteria.

  ## Parameters

    - `query`: Search query string
    - `opts`: Optional search parameters:
      - `:filters`: Map of filter criteria (e.g., `%{country: "US"}`)

  ## Examples

      AppleBusinessRegistry.search_businesses("coffee", filters: %{country: "US", locality: "San Francisco"})
  """
  @spec search_businesses(String.t(), opts) :: {:ok, list(map())} | {:error, term()}
  def search_businesses(query, opts \\ []) when is_binary(query) do
    params = Keyword.get(opts, :filters, %{})
    merged_opts = Keyword.put(opts, :q, query)
    Client.get("/v1/businesses/search", Keyword.put(merged_opts, :params, params))
  end

  @doc """
  Validate a business registration before creating it.

  ## Parameters

    - `attrs`: Map of business attributes to validate

  Returns `{:ok, validation_result}` if validation passes, or `{:error, reason}` if it fails.
  """
  @spec validate_business(map(), opts) :: {:ok, map()} | {:error, term()}
  def validate_business(attrs, opts \\ []) when is_map(attrs) do
    Client.post("/v1/businesses/validate", attrs, opts)
  end

  @doc """
  Validate a location before creating it.

  ## Parameters

    - `attrs`: Map of location attributes to validate

  Returns `{:ok, validation_result}` if validation passes, or `{:error, reason}` if it fails.
  """
  @spec validate_location(map(), opts) :: {:ok, map()} | {:error, term()}
  def validate_location(attrs, opts \\ []) when is_map(attrs) do
    Client.post("/v1/locations/validate", attrs, opts)
  end
end
