defmodule Thoughtshare.AuthController do
  use Thoughtshare.Web, :controller
  alias Thoughtshare.Cyphers
  alias Neo4j.Sips, as: Neo4j
  alias Comeonin.Bcrypt
  alias Poison.Parser

  def login(conn, req) do
    %{"username" => username, "password" => password} = req

    fetch_user = """
      MATCH (user:USER)
      WHERE user.username = \"#{username}\"
      RETURN user;
    """
    {:ok, fetch_user_res} = Neo4j.query(Neo4j.conn, fetch_user)

    unless length(fetch_user_res) == 0 do
      # Parser.parse!(~s(fetch_user_res), as: User)
      user = hd(fetch_user_res)["user"]
      matched = Bcrypt.checkpw(password, user["password"])
      if matched do
        {:ok, jwt, full_claims} = Guardian.encode_and_sign(user, :token)
        json conn |> put_status(200), %{"data" => %{"token" => jwt}}
      else
        json conn |> put_status(400), %{"message" => "Bad username/password"}
      end
    else
      json conn |> put_status(400), %{"message" => "Bad username/password"}
    end
  end

  def me(conn, req) do
    resource = Guardian.Plug.current_resource(conn)
    json conn |> put_status(200), %{"data" => resource}
  end

  def unauthenticated_api(conn, _req) do
    json conn |> put_status(401), %{"message" => "Unauthenticated request"}
  end
end
