defmodule Proxy do
  use TypedStruct

  @type type :: :http | :socks

  typedstruct do
    field(:type, type, required: true)
    field(:host, String.t(), required: true)
    field(:port, port, required: true)
  end
end

defmodule ProxyCheck do
  @spec to_option(Proxy.t()) :: {:proxy, any}
  defp to_option(proxy) do
    case proxy do
      %Proxy{type: :http, host: host, port: port} -> {:proxy, {host, port}}
      %Proxy{type: :socks, host: host, port: port} -> {:proxy, {:socks5, to_charlist(host), port}}
    end
  end

  @spec check(Proxy.t()) :: Proxy.type() | :err
  defp check(%Proxy{type: type} = proxy) do
    case :hackney.request(:head, "https://adel.lol", [], "", [to_option(proxy)]) do
      {:ok, 200, _headers} -> type
      _ -> :err
    end
  end

  @spec check_tup({String.t(), port}) :: Proxy.type() | :err
  def check_tup({host, port}) do
    parent = self()

    Task.start(fn ->
      send(parent, check(%Proxy{type: :http, host: host, port: port}))
    end)

    Task.start(fn ->
      send(parent, check(%Proxy{type: :socks, host: host, port: port}))
    end)

    receive do
      :err ->
        receive do
          x -> x
        after
          10_000 -> :err
        end

      x ->
        x
    after
      10_000 -> :err
    end
  end

  def check_list(list) do
    String.split(list, "\n", trim: true)
    |> Enum.flat_map(fn line ->
      case String.split(line, ":", trim: true) do
        [host, port] -> [{host, String.to_integer(port)}]
        _ -> []
      end
    end)
  end
end
