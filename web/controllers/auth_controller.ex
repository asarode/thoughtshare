defmodule Thoughtshare.AuthController do
  use Thoughtshare.Web, :controller
  alias Thoughtshare.Cyphers
  alias Thoughtshare.User
  alias Neo4j.Sips, as: Neo4j
  alias Comeonin.Bcrypt
  alias Poison.Parser

  def login(conn, req) do
    %{"username" => username, "password" => password} = req

    {:ok, users} = User.find(username: username)
    if length(users) == 0 do
      json conn |> put_status(400), bad_credentials()
    end

    user = List.first(users)
    case Bcrypt.checkpw(password, user.password) do
      true ->
        {:ok, jwt, full_claims} = Guardian.encode_and_sign(user, :token)
        json conn |> put_status(200), %{"data" => %{"token" => jwt}}
      false -> json conn |> put_status(400), bad_credentials()
    end
  end

  def me(conn, req) do
    resource = Guardian.Plug.current_resource(conn)
    json conn |> put_status(200), %{"data" => resource}
  end

  def unauthenticated_api(conn, _req) do
    json conn |> put_status(401), %{"message" => "Unauthenticated request"}
  end

  defp bad_credentials do
    %{
      errors: [%{
        status: "400",
        code: "Invalid credentials",
        detail: "The username or password you entered were not valid"
      }]
    }
  end
end
