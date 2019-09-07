defmodule LiveproxyWeb.ProxyLive do
  use Phoenix.LiveView
  import Phoenix.HTML.Form

  @type assigns :: %{required(:state) => :idle | [any]}
  @type socket :: %Phoenix.LiveView.Socket{}

  def mount(_state, socket) do
    {:ok, assign(socket, :state, :idle)}
  end

  defp btn_text(:idle), do: "Check"
  defp btn_text(_), do: "Checking..."

  @spec render(assigns) :: Phoenix.LiveView.Rendered.t()
  def render(assigns) do
    ~L"""
    <h1>Proxy Checker</h1>

    <%= f = form_for :check, "#", [phx_submit: :check] %>
    <%= textarea f, :proxies %>
    <%= submit btn_text(@state), disabled: @state != :idle %>
    </form>

    <%= if @state != :idle do %>
      <ul>
        <%= for pair <- @state do %>
          <li><%= inspect(pair) %></li>
        <% end %>
      </ul
    <% end %>
    """
  end

  @spec handle_event(<<_::40>>, map, socket) :: {:noreply, socket}
  def handle_event("check", %{"check" => %{"proxies" => list}}, socket) do
    pairs = ProxyCheck.check_list(list)
    {:noreply, socket |> assign(:state, pairs)}
  end
end
