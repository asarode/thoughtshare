defmodule Thoughtshare.PageController do
  use Thoughtshare.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
