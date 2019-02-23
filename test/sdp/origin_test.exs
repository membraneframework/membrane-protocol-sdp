defmodule Membrane.Protocol.SDP.OriginTest do
  use ExUnit.Case

  alias Membrane.Protocol.SDP.Origin

  describe "Origin parser" do
    test "processes valid origin declaration" do
      assert {:ok, origin} = Origin.parse("jdoe 2890844526 2890842807 IN IP4 10.47.16.5")

      assert origin == %Origin{
               address_type: "IP4",
               network_type: "IN",
               session_id: "2890844526",
               session_version: "2890842807",
               unicast_address: {10, 47, 16, 5},
               username: "jdoe"
             }
    end

    test "returns an error if declaration is invalid" do
      assert {:error, :invalid_origin} = Origin.parse("jdoe 2890844526 2890842807")
    end

    test "returns an error if declaration contains not supported address type" do
      assert {:error, {:not_supported_addr_type, "NOTIP"}} =
               Origin.parse("jdoe 2890844526 2890842807 IN NOTIP 10.47.16.5")
    end

    test "returns an error if declaration contains non parsable ip" do
      assert {:error, :einval} = Origin.parse("jdoe 2890844526 2890842807 IN IP4 10.280.16.5")
    end
  end
end