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
      id: fetch(attrs, "id", :id),
      name: fetch(attrs, "name", :name),
      organization_type: fetch(attrs, "organizationType", :organization_type),
      primary_phone: fetch(attrs, "primaryPhone", :primary_phone),
      primary_email: fetch(attrs, "primaryEmail", :primary_email),
      website: fetch(attrs, "website", :website),
      description: fetch(attrs, "description", :description),
      status: fetch(attrs, "status", :status),
      created_at: fetch(attrs, "createdAt", :created_at),
      updated_at: fetch(attrs, "updatedAt", :updated_at)
    }
  end

  defp fetch(attrs, string_key, atom_key), do: attrs[string_key] || attrs[atom_key]

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
