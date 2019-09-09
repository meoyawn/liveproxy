defmodule Proxy do
  @type proxy :: {String.t(), port}
  @type type :: :http | :socks
  @type req :: {proxy, type}
  @type resp :: {type, String.t(), non_neg_integer} | :err

  @spec check(proxy, type) :: resp
  defp check({host, port} = proxy, type) do
    proxy =
      case type do
        :http -> proxy
        :socks -> {:socks5, to_charlist(host), port}
      end

    start = System.monotonic_time(:millisecond)

    case :hackney.request(:head, "https://adel.lol", [], "", proxy: proxy, pool: :massive) do
      {:ok, 200, _headers} ->
        finish = System.monotonic_time(:millisecond)
        %{country: %{registered_country: %{name: country}}} = Geolix.lookup(host)
        {type, country, finish - start}

      _ ->
        :err
    end
  end

  def timeout, do: 15_000

  @spec check(proxy) :: resp
  def check(proxy) do
    parent = self()

    {:ok, pid1} = Task.start(fn -> send(parent, check(proxy, :http)) end)
    {:ok, pid2} = Task.start(fn -> send(parent, check(proxy, :socks)) end)

    ret =
      receive do
        :err ->
          receive do
            x -> x
          after
            timeout() -> :err
          end

        x ->
          x
      after
        timeout() -> :err
      end

    true = Process.exit(pid1, :kill)
    true = Process.exit(pid2, :kill)

    ret
  end

  @spec parse_list(String.t()) :: [proxy]
  def parse_list(list) do
    String.split(list, "\n", trim: true)
    |> Enum.flat_map(fn line ->
      with [host, port_s] <- String.split(line, ":", trim: true),
           {port, _} <- Integer.parse(port_s) do
        [{host, port}]
      else
        _ -> []
      end
    end)
  end
end
