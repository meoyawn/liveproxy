defmodule LiveproxyWeb.PageController do
  use LiveproxyWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
