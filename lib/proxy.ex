defmodule Proxy do
  use TypedStruct

  @type type :: :http | :socks

  typedstruct do
    field(:type, type)
    field(:host, String.t())
    field(:port, port)
  end
end

defmodule ProxyOk do
  use TypedStruct

  typedstruct do
    field(:type, Proxy.type())
  end
end

defmodule ProxyCheck do
  @spec to_option(Proxy.t()) :: {:proxy, any}
  defp to_option(%Proxy{type: :http, host: host, port: port}), do: {:proxy, {host, port}}

  defp to_option(%Proxy{type: :socks, host: host, port: port}),
    do: {:proxy, {:socks5, host, port}}

  @spec check(Proxy.t(), 1..2) :: Proxy.type() | :err
  defp check(proxy, attempt \\ 1) do
    case :hackney.request(:head, "https://adel.lol", [], "", [to_option(proxy)]) do
      {:ok, 200, _headers, _client} ->
        :ok

      _ ->
        if attempt == 2 do
          :err
        else
          check(proxy, attempt + 1)
        end
    end
  end

  def check_tup({host, port}) do
    parent = self()

    Task.start_link(fn ->
      send(parent, check(%Proxy{type: :http, host: host, port: port}))
    end)

    Task.start_link(fn ->
      send(parent, check(%Proxy{type: :socks, host: host, port: port}))
    end)

    receive do
      :err ->
        receive do
          x -> x
        end

      x ->
        x
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
