defmodule AppleBusinessRegistry.Location do
  @moduledoc """
  Location struct representing a business location in Apple Business Registry.

  ## Fields

    - `id`: Unique identifier for the location
    - `business_id`: ID of the parent business
    - `name`: Location name (e.g., "Main Store", "Downtown Branch")
    - `address`: Street address
    - `locality`: City/locality
    - `administrative_area`: State/province
    - `postal_code`: Postal/ZIP code
    - `country`: ISO 3166-1 alpha-2 country code
    - `phone`: Location-specific phone number
    - `latitude`: Latitude coordinate
    - `longitude`: Longitude coordinate
    - `status`: Location status ("active", "pending", "closed")
    - `created_at`: ISO 8601 timestamp when the location was created
    - `updated_at`: ISO 8601 timestamp when the location was last updated
  """

  defstruct [
    :id,
    :business_id,
    :name,
    :address,
    :locality,
    :administrative_area,
    :postal_code,
    :country,
    :phone,
    :latitude,
    :longitude,
    :status,
    :created_at,
    :updated_at
  ]

  @type t :: %__MODULE__{
          id: String.t() | nil,
          business_id: String.t() | nil,
          name: String.t() | nil,
          address: String.t() | nil,
          locality: String.t() | nil,
          administrative_area: String.t() | nil,
          postal_code: String.t() | nil,
          country: String.t() | nil,
          phone: String.t() | nil,
          latitude: float() | nil,
          longitude: float() | nil,
          status: String.t() | nil,
          created_at: String.t() | nil,
          updated_at: String.t() | nil
        }

  @doc """
  Decode a location map into a `%Location{}` struct.
  """
  @spec from_map(map()) :: t()
  def from_map(attrs) when is_map(attrs) do
    %__MODULE__{
      id: attrs["id"] || attrs[:id],
      business_id: attrs["businessId"] || attrs[:business_id],
      name: attrs["name"] || attrs[:name],
      address: attrs["address"] || attrs[:address],
      locality: attrs["locality"] || attrs[:locality],
      administrative_area: attrs["administrativeArea"] || attrs[:administrative_area],
      postal_code: attrs["postalCode"] || attrs[:postal_code],
      country: attrs["country"] || attrs[:country],
      phone: attrs["phone"] || attrs[:phone],
      latitude: parse_coordinate(attrs["latitude"] || attrs[:latitude]),
      longitude: parse_coordinate(attrs["longitude"] || attrs[:longitude]),
      status: attrs["status"] || attrs[:status],
      created_at: attrs["createdAt"] || attrs[:created_at],
      updated_at: attrs["updatedAt"] || attrs[:updated_at]
    }
  end

  @doc """
  Encode a `%Location{}` struct into a map for API requests.
  """
  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = location) do
    %{
      "name" => location.name,
      "address" => location.address,
      "locality" => location.locality,
      "administrativeArea" => location.administrative_area,
      "postalCode" => location.postal_code,
      "country" => location.country,
      "phone" => location.phone,
      "latitude" => location.latitude,
      "longitude" => location.longitude
    }
    |> Enum.reject(fn {_, v} -> is_nil(v) end)
    |> Map.new()
  end

  defp parse_coordinate(nil), do: nil
  defp parse_coordinate(val) when is_float(val), do: val
  defp parse_coordinate(val) when is_integer(val), do: val * 1.0

  defp parse_coordinate(val) when is_binary(val) do
    case Float.parse(val) do
      {num, _} -> num
      :error -> nil
    end
  end
end
