defmodule Membrane.Protocol.SDP.Timezone.Correction do
  @moduledoc """
  This module represents single SDP Timezone Correction used
  for translating base time for rebroadcasts.

  For more details please see [RFC4566 Section 5.11](https://tools.ietf.org/html/rfc4566#section-5.11)
  """

  @enforce_keys [:adjustment_time, :offset]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
          adjustment_time: non_neg_integer(),
          offset: -12..12
        }

  @spec parse(binary()) :: {:ok, t()} | {:error, :invalid_timezone}
  def parse(correction) do
    case String.split(correction) do
      [adjustment_time, offset] -> wrap_correction(adjustment_time, offset)
      _ -> {:error, :invalid_timezone}
    end
  end

  defp wrap_correction(adjustment_time, offset) do
    with {adjustment_time, ""} <- Integer.parse(adjustment_time),
         {offset, rest} when rest == "" or rest == "h" <- Integer.parse(offset) do
      correction = %__MODULE__{
        adjustment_time: adjustment_time,
        offset: offset
      }

      {:ok, correction}
    else
      _ -> {:error, :invalid_timezone}
    end
  end
end

defimpl Membrane.Protocol.SDP.Serializer, for: Membrane.Protocol.SDP.Timezone.Correction do
  def serialize(correction) do
    serialized_offset =
      if correction.offset == 0 do
        Integer.to_string(correction.offset)
      else
        Integer.to_string(correction.offset) <> "h"
      end

    Integer.to_string(correction.adjustment_time) <> " " <> serialized_offset
  end
end