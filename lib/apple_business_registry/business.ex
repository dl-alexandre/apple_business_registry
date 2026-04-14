defmodule AppleBusinessRegistry.Business do
  @moduledoc """
  Business struct representing a registered business in Apple Business Registry.

  ## Fields

    - `id`: Unique identifier for the business
    - `name`: Business name
    - `organization_type`: Organization type (e.g., "company", "nonprofit", "government")
    - `primary_phone`: Primary contact phone number
    - `primary_email`: Primary contact email
    - `website`: Business website URL
    - `description`: Business description
    - `status`: Registration status ("active", "pending", "suspended")
    - `created_at`: ISO 8601 timestamp when the business was registered
    - `updated_at`: ISO 8601 timestamp when the business was last updated
  """

  defstruct [
    :id,
    :name,
    :organization_type,
    :primary_phone,
    :primary_email,
    :website,
    :description,
    :status,
    :created_at,
    :updated_at
  ]

  @type t :: %__MODULE__{
          id: String.t() | nil,
          name: String.t() | nil,
          organization_type: String.t() | nil,
          primary_phone: String.t() | nil,
          primary_email: String.t() | nil,
          website: String.t() | nil,
          description: String.t() | nil,
          status: String.t() | nil,
          created_at: String.t() | nil,
          updated_at: String.t() | nil
        }

  @doc """
  Decode a business map into a `%Business{}` struct.
  """
  @spec from_map(map()) :: t()
  def from_map(attrs) when is_map(attrs) do
    %__MODULE__{
      id: attrs["id"] || attrs[:id],
      name: attrs["name"] || attrs[:name],
      organization_type: attrs["organizationType"] || attrs[:organization_type],
      primary_phone: attrs["primaryPhone"] || attrs[:primary_phone],
      primary_email: attrs["primaryEmail"] || attrs[:primary_email],
      website: attrs["website"] || attrs[:website],
      description: attrs["description"] || attrs[:description],
      status: attrs["status"] || attrs[:status],
      created_at: attrs["createdAt"] || attrs[:created_at],
      updated_at: attrs["updatedAt"] || attrs[:updated_at]
    }
  end

  @doc """
  Encode a `%Business{}` struct into a map for API requests.
  """
  @spec to_map(t()) :: map()
  def to_map(%__MODULE__{} = business) do
    %{
      "name" => business.name,
      "organizationType" => business.organization_type,
      "primaryPhone" => business.primary_phone,
      "primaryEmail" => business.primary_email,
      "website" => business.website,
      "description" => business.description
    }
    |> Enum.reject(fn {_, v} -> is_nil(v) end)
    |> Map.new()
  end
end
