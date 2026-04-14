defmodule AppleBusinessRegistry.LocationTest do
  use ExUnit.Case, async: true

  alias AppleBusinessRegistry.Location

  test "from_map/1 decodes location JSON into struct" do
    map = %{
      "id" => "loc_123",
      "businessId" => "biz_456",
      "name" => "Main Store",
      "address" => "1 Infinite Loop",
      "locality" => "Cupertino",
      "administrativeArea" => "CA",
      "postalCode" => "95014",
      "country" => "US",
      "phone" => "+1-555-123-4567",
      "latitude" => 37.3318,
      "longitude" => -122.0312,
      "status" => "active",
      "createdAt" => "2024-01-15T10:30:00Z",
      "updatedAt" => "2024-01-20T14:45:00Z"
    }

    location = Location.from_map(map)

    assert location.id == "loc_123"
    assert location.business_id == "biz_456"
    assert location.name == "Main Store"
    assert location.address == "1 Infinite Loop"
    assert location.locality == "Cupertino"
    assert location.administrative_area == "CA"
    assert location.postal_code == "95014"
    assert location.country == "US"
    assert location.phone == "+1-555-123-4567"
    assert location.latitude == 37.3318
    assert location.longitude == -122.0312
    assert location.status == "active"
    assert location.created_at == "2024-01-15T10:30:00Z"
    assert location.updated_at == "2024-01-20T14:45:00Z"
  end

  test "from_map/1 handles string coordinates" do
    map = %{
      "latitude" => "37.7749",
      "longitude" => "-122.4194"
    }

    location = Location.from_map(map)

    assert location.latitude == 37.7749
    assert location.longitude == -122.4194
  end

  test "from_map/1 handles integer coordinates" do
    map = %{
      "latitude" => 40,
      "longitude" => -74
    }

    location = Location.from_map(map)

    assert location.latitude == 40.0
    assert location.longitude == -74.0
  end

  test "from_map/1 handles atom keys" do
    map = %{
      id: "loc_789",
      name: "Downtown Branch",
      latitude: 37.7849
    }

    location = Location.from_map(map)

    assert location.id == "loc_789"
    assert location.name == "Downtown Branch"
    assert location.latitude == 37.7849
  end

  test "to_map/1 encodes struct for API request" do
    location = %Location{
      name: "Midtown Office",
      address: "350 5th Ave",
      locality: "New York",
      administrative_area: "NY",
      postal_code: "10118",
      country: "US",
      phone: "+1-555-789-0123",
      latitude: 40.7484,
      longitude: -73.9857
    }

    map = Location.to_map(location)

    assert map["name"] == "Midtown Office"
    assert map["address"] == "350 5th Ave"
    assert map["locality"] == "New York"
    assert map["administrativeArea"] == "NY"
    assert map["postalCode"] == "10118"
    assert map["country"] == "US"
    assert map["phone"] == "+1-555-789-0123"
    assert map["latitude"] == 40.7484
    assert map["longitude"] == -73.9857
  end

  test "to_map/1 omits nil fields" do
    location = %Location{name: "Pop-up Store", country: "US"}

    map = Location.to_map(location)

    assert map["name"] == "Pop-up Store"
    assert map["country"] == "US"
    assert not Map.has_key?(map, "address")
    assert not Map.has_key?(map, "latitude")
  end
end
