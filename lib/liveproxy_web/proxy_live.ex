defmodule ProxyList do
  use TypedStruct

  @type type :: {Proxy.proxy(), Proxy.resp()}

  typedstruct do
    field(:success, [type], required: true)
    field(:working, MapSet.t({String.t(), port}), required: true)
    field(:failed, [type], required: true)
  end
end

defmodule LiveproxyWeb.ProxyLive do
  use Phoenix.LiveView
  import Phoenix.HTML.Form

  @type state :: :idle | ProxyList.t()
  @type assigns :: %{required(:state) => state}
  @type socket :: %Phoenix.LiveView.Socket{}

  def mount(_state, socket) do
    {:ok, sup} = Task.Supervisor.start_link()
    {:ok, socket |> assign(:state, :idle) |> assign(:sup, sup)}
  end

  @spec terminate(any, socket) :: :ok
  def terminate(_reason, %Phoenix.LiveView.Socket{assigns: %{sup: sup}}) do
    Supervisor.stop(sup)
  end

  @empty MapSet.new()

  @spec working(state) :: boolean
  defp working(:idle), do: false
  defp working(%ProxyList{working: x}) when x == @empty, do: false
  defp working(%ProxyList{working: _}), do: true

  @spec btn_text(state) :: String.t()
  defp btn_text(state) do
    if working(state), do: "Checking...", else: "Check"
  end

  defp type(:socks), do: "SOCKS5"
  defp type(:http), do: "HTTP"

  @spec render(assigns) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~L"""
    <h1>Proxy Checker</h1>

    <%= f = form_for :check, "#", [phx_submit: :check] %>
    <%= textarea f, :proxies %>
    <%= submit btn_text(@state), disabled: working(@state) %>
    </form>

    <%= if @state != :idle do %>
      <%= if @state.success != [] do %>
        <h2>Alive</h2>
      <% end %>
      <table>
        <%= for {{host,port}, {type, country}} <- @state.success do %>
          <tr>
            <td><%= "#{host}:#{port}" %></td>
            <td><%= type(type) %></td>
            <td><%= country %></td>
          </tr>
        <% end %>
      </table>

      <%= if @state.failed != [] do %>
        <h2>Dead</h2>
      <% end %>
      <table>
        <%= for {{host,port}, _} <- @state.failed do %>
          <tr>
            <td><%= "#{host}:#{port}" %></td>
          </tr>
        <% end %>
      </table>
    <% end %>
    """
  end

  @spec handle_event(<<_::40>>, map, socket) :: {:noreply, socket}
  def handle_event(
        "check",
        %{"check" => %{"proxies" => list}},
        %Phoenix.LiveView.Socket{assigns: %{sup: sup}} = socket
      ) do
    parent = self()
    proxies = Proxy.parse_list(list)

    for proxy <- proxies do
      {:ok, _} =
        Task.Supervisor.start_child(
          sup,
          fn -> send(parent, {proxy, Proxy.check(proxy)}) end,
          shutdown: :brutal_kill
        )
    end

    {:noreply,
     socket |> assign(:state, %ProxyList{success: [], failed: [], working: MapSet.new(proxies)})}
  end

  @spec handle_info({Proxy.proxy(), :err}, socket) :: {:noreply, socket}
  def handle_info(
        {proxy, :err} = result,
        %Phoenix.LiveView.Socket{
          assigns: %{state: %ProxyList{working: work, failed: fail} = list}
        } = socket
      ) do
    {:noreply,
     socket
     |> assign(:state, %{list | working: MapSet.delete(work, proxy), failed: fail ++ [result]})}
  end

  @spec handle_info(Proxy.req(), socket) :: {:noreply, socket}
  def handle_info(
        {proxy, _} = result,
        %Phoenix.LiveView.Socket{
          assigns: %{state: %ProxyList{success: suc, working: work} = list}
        } = socket
      ) do
    {:noreply,
     socket
     |> assign(:state, %{list | success: suc ++ [result], working: MapSet.delete(work, proxy)})}
  end
end
