defmodule Proxy do
  use TypedStruct

  typedstruct do
    field(:type, :http | :socks)
    field(:host, String.t())
    field(:port, port)
  end
end

defmodule ProxyCheck do
  @spec to_option(Proxy.t()) :: {:proxy, any}
  defp to_option(%Proxy{type: :http, host: host, port: port}),
    do: {:proxy, {host, port}}

  defp to_option(%Proxy{type: :socks, host: host, port: port}),
    do: {:proxy, {:socks5, host, port}}

  @spec check(Proxy.t(), 1..2) :: :ok | :err
  def check(proxy, attempt \\ 1) do
    case :hackney.request(:head, "https://adelnizamutdinov.github.io", [], "", [to_option(proxy)]) do
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

  def check(host, port) do
    Task.start_link(fn ->
      check(%Proxy{type: :http, host: host, port: port})
    end)

    Task.start_link(fn ->
      check(%Proxy{type: :socks, host: host, port: port})
    end)
  end

  def check_str(str) do
  end
end
