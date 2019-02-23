defmodule Membrane.Protocol.SDP.TimezoneTest do
  use ExUnit.Case

  alias Membrane.Protocol.SDP.Timezone

  describe "Timezone parser" do
    test "processes valid timezone correction description" do
      assert {:ok, corrections} = Timezone.parse("2882844526 -1h 2898848070 0")

      assert corrections == [
               %Timezone{adjustment_time: 2_882_844_526, offset: "-1h"},
               %Timezone{adjustment_time: 2_898_848_070, offset: "0"}
             ]
    end

    test "returns an error if timezone correction is not valid" do
      assert {:error, :invalid_timezone} = Timezone.parse("2882844526 -1h 2898848070")
    end
  end
end