defmodule ProxyList do
  use TypedStruct

  @type type :: {{String.t(), port}, Proxy.type() | :err}

  typedstruct do
    field(:success, [type], required: true)
    field(:working, [{String.t(), port}], required: true)
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
    {:ok, assign(socket, :state, :idle)}
  end

  @spec working(state) :: boolean
  defp working(:idle), do: false
  defp working(%ProxyList{working: []}), do: false
  defp working(%ProxyList{working: _}), do: true

  @spec btn_text(state) :: String.t()
  defp btn_text(state) do
    if working(state), do: "Checking...", else: "Check"
  end

  @spec render(assigns) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~L"""
    <h1>Proxy Checker</h1>

    <%= f = form_for :check, "#", [phx_submit: :check] %>
    <%= textarea f, :proxies %>
    <%= submit btn_text(@state), disabled: working(@state) %>
    </form>

    <%= if @state != :idle do %>
      <%= inspect(@state) %>
    <% end %>
    """
  end

  @spec handle_event(<<_::40>>, map, socket) :: {:noreply, socket}
  def handle_event("check", %{"check" => %{"proxies" => list}}, socket) do
    parent = self()
    proxies = Proxy.check_list(list)

    for proxy <- proxies do
      Task.start(fn -> send(parent, {proxy, Proxy.check(proxy)}) end)
    end

    {:noreply, socket |> assign(:state, %ProxyList{success: [], failed: [], working: proxies})}
  end

  @spec handle_info({Proxy.proxy(), :err}, socket) :: {:noreply, socket}
  def handle_info(
        {pair, :err} = result,
        %Phoenix.LiveView.Socket{
          assigns: %{state: %ProxyList{working: work, failed: fail} = list}
        } = socket
      ) do
    {:noreply,
     socket
     |> assign(:state, %{list | working: List.delete(work, pair), failed: fail ++ [result]})}
  end

  @spec handle_info(Proxy.req(), socket) :: {:noreply, socket}
  def handle_info(
        {pair, _type} = result,
        %Phoenix.LiveView.Socket{
          assigns: %{state: %ProxyList{success: suc, working: work} = list}
        } = socket
      ) do
    {:noreply,
     socket
     |> assign(:state, %{list | success: suc ++ [result], working: List.delete(work, pair)})}
  end
end
