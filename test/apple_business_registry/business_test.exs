defmodule AppleBusinessRegistry.BusinessTest do
  use ExUnit.Case, async: true

  alias AppleBusinessRegistry.Business

  test "from_map/1 decodes business JSON into struct" do
    map = %{
      "id" => "biz_123",
      "name" => "Acme Inc",
      "organizationType" => "company",
      "primaryPhone" => "+1-555-123-4567",
      "primaryEmail" => "contact@acme.com",
      "website" => "https://acme.com",
      "description" => "Widget manufacturer",
      "status" => "active",
      "createdAt" => "2024-01-15T10:30:00Z",
      "updatedAt" => "2024-01-20T14:45:00Z"
    }

    business = Business.from_map(map)

    assert business.id == "biz_123"
    assert business.name == "Acme Inc"
    assert business.organization_type == "company"
    assert business.primary_phone == "+1-555-123-4567"
    assert business.primary_email == "contact@acme.com"
    assert business.website == "https://acme.com"
    assert business.description == "Widget manufacturer"
    assert business.status == "active"
    assert business.created_at == "2024-01-15T10:30:00Z"
    assert business.updated_at == "2024-01-20T14:45:00Z"
  end

  test "from_map/1 handles atom keys" do
    map = %{
      id: "biz_456",
      name: "Beta Corp",
      status: "pending"
    }

    business = Business.from_map(map)

    assert business.id == "biz_456"
    assert business.name == "Beta Corp"
    assert business.status == "pending"
  end

  test "from_map/1 handles partial data" do
    map = %{"id" => "biz_789", "name" => "Gamma LLC"}

    business = Business.from_map(map)

    assert business.id == "biz_789"
    assert business.name == "Gamma LLC"
    assert business.status == nil
    assert business.primary_email == nil
  end

  test "to_map/1 encodes struct for API request" do
    business = %Business{
      name: "Delta Co",
      organization_type: "nonprofit",
      primary_phone: "+1-555-987-6543",
      primary_email: "info@delta.org",
      website: "https://delta.org",
      description: "Nonprofit organization"
    }

    map = Business.to_map(business)

    assert map["name"] == "Delta Co"
    assert map["organizationType"] == "nonprofit"
    assert map["primaryPhone"] == "+1-555-987-6543"
    assert map["primaryEmail"] == "info@delta.org"
    assert map["website"] == "https://delta.org"
    assert map["description"] == "Nonprofit organization"
  end

  test "to_map/1 omits nil fields" do
    business = %Business{name: "Epsilon Ltd", organization_type: "company"}

    map = Business.to_map(business)

    assert map["name"] == "Epsilon Ltd"
    assert map["organizationType"] == "company"
    assert not Map.has_key?(map, "primaryPhone")
    assert not Map.has_key?(map, "website")
  end
end
