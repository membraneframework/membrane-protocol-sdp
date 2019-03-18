defmodule Membrane.Protocol.SDP.ConnectionData do
  @moduledoc """
  This module represents Connection Information.
  Address can be represented by either:
   - IPv4 address
   - IPv6 address
   - FQDN

  In case of IPv4 and IPv6 multicast addresses there can be more than one
  parsed from single SDP field if it is described using slash notation.

  Sessions using an IPv4 multicast connection address MUST also have
  a time to live (TTL) value present in addition to the multicast
  address.

  For more details please see [RFC4566 Section 5.7]|(https://tools.ietf.org/html/rfc4566#section-5.7
  """
  use Bunch

  @enforce_keys [:network_type, :address]
  defstruct @enforce_keys

  defmodule IP4 do
    @moduledoc false
    @enforce_keys [:value]
    defstruct @enforce_keys ++ [:ttl]

    @type t :: %__MODULE__{
            value: :inet.ip4_address(),
            ttl: 0..255 | nil
          }
  end

  defmodule IP6 do
    @moduledoc false
    @enforce_keys [:value]
    defstruct @enforce_keys

    @type t :: %__MODULE__{
            value: :inet.ip6_address()
          }
  end

  @type sdp_address :: IP6.t() | IP4.t() | binary()

  @type reason :: :invalid_address | :invalid_connection_data | :option_nan | :wrong_ttl

  @spec parse(binary()) :: {:ok, [sdp_address()] | sdp_address()} | {:error, reason}
  def parse(connection_string) do
    with [_nettype, addrtype, connection_address] <- String.split(connection_string, " "),
         [address | optional] <- String.split(connection_address, "/") do
      parse_address(address, addrtype, optional)
    else
      list when is_list(list) -> {:error, :invalid_connection_data}
    end
  end

  defp parse_address(address, addrtype, optional) do
    with {:ok, address} <- address |> to_charlist() |> :inet.parse_address(),
         {:ok, addresses} <- handle_address(address, addrtype, optional) do
      {:ok, addresses}
    else
      {:error, :einval} ->
        {:ok, address}

      {:error, _} = error ->
        error
    end
  end

  defp handle_address(address, type, options)
  defp handle_address(address, "IP4", []), do: {:ok, %IP4{value: address}}

  defp handle_address(address, "IP4", [ttl]) do
    with {:ok, ttl} <- parse_ttl(ttl) do
      {:ok, %IP4{value: address, ttl: ttl}}
    end
  end

  defp handle_address(address, "IP4", [ttl, count]) do
    with {:ok, ttl} <- parse_numeric_option(ttl),
         ttl when ttl in 0..255 <- ttl,
         {:ok, count} <- parse_numeric_option(count),
         {:ok, addresses} <- unfold_addresses(address, count) do
      addresses = Enum.map(addresses, fn address -> %IP4{value: address, ttl: ttl} end)
      {:ok, addresses}
    else
      wrong_ttl when is_number(wrong_ttl) -> {:error, :wrong_ttl}
      {:error, _} = error -> error
    end
  end

  defp handle_address(address, "IP6", []), do: {:ok, %IP6{value: address}}

  defp handle_address(address, "IP6", [count]) do
    with {:ok, count} <- parse_numeric_option(count),
         {:ok, addresses} <- unfold_addresses(address, count) do
      addresses = Enum.map(addresses, fn address -> %IP6{value: address} end)
      {:ok, addresses}
    end
  end

  defp handle_address(_, _, _), do: {:error, :invalid_address}

  defp parse_ttl(ttl) do
    ttl
    |> parse_numeric_option()
    ~>> ({:ok, ttl} when ttl not in 0..255 -> {:error, :wrong_ttl})
  end

  defp parse_numeric_option(option) do
    option
    |> Integer.parse()
    ~> (
      {number, ""} -> {:ok, number}
      _ -> {:error, :option_nan}
    )
  end

  defp unfold_addresses(address, count, acc \\ [])
  defp unfold_addresses(_, 0, acc), do: {:ok, Enum.reverse(acc)}

  defp unfold_addresses(address, count, acc) do
    with {:ok, next_ip} <- increment_ip(address) do
      unfold_addresses(next_ip, count - 1, [address | acc])
    end
  end

  defp increment_ip(ip) do
    index = tuple_size(ip) - 1
    value = elem(ip, index)

    if value + 1 <= max_octet_value(tuple_size(ip)) do
      {:ok, put_elem(ip, index, value + 1)}
    else
      {:error, :invalid_address}
    end
  end

  defp max_octet_value(size)
  defp max_octet_value(8), do: 65_535
  defp max_octet_value(4), do: 255
end
