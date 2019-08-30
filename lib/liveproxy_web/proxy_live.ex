defmodule LiveproxyWeb.ProxyLive do
  use Phoenix.LiveView
  import Phoenix.HTML.Form

  @type assigns :: %{required(:state) => :idle | :loading}
  @type socket :: %Phoenix.LiveView.Socket{}

  def mount(_state, socket) do
    {:ok, assign(socket, :state, :idle)}
  end

  @spec render(assigns) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~L"""
    <h1>Proxy Checker</h1>

    <%= f = form_for :check, "#", [phx_submit: :check] %>
    <%= textarea f, :proxies %>
    <%= submit "Check" %>
    </form>

    <%= if @state == :loading do %>
    <div>Loading...</div>
    <% end %>
    """
  end

  @spec handle_event(<<_::40>>, map, socket) :: {:noreply, socket}
  def handle_event("check", %{"check" => %{"proxies" => list}}, socket) do
    IO.inspect(list)

    {:noreply, assign(socket, :state, :loading)}
  end
end
