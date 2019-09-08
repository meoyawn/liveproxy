defmodule LiveproxyWeb.PageControllerTest do
  use LiveproxyWeb.ConnCase, async: true

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert html_response(conn, 200) =~ "Proxy Checker"
  end
end
