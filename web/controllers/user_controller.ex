defmodule Thoughtshare.UserController do
  use Thoughtshare.Web, :controller
  alias Thoughtshare.User
  alias Thoughtshare.Cyphers
  alias Neo4j.Sips, as: Neo4j
  alias Comeonin.Bcrypt

  def index(conn, %{"id" => user_id}) do
    User.find(id: user_id)
  end

  def show(conn, %{"id" => user_id}) do
    # %{"id" => user_id} = params
    # fetch_user_by_id_cypher = """
    #   MATCH (user:USER)
    #   WHERE user.id = \"#{user_id}\"
    #   RETURN user;
    # """
    # {:ok, fetch_res} = Neo4j.tx_commit(Neo4j.conn, fetch_user_by_id_cypher)

    {:ok, user} = User.find(id: user_id)

    created_thoughts_cypher = """
      MATCH (user:USER {id: #{user_id}})
      WITH user
      MATCH (user)<-[:CREATED_BY]-(thought:THOUGHT)
      RETURN collect(id: thought.id)
    """
    {:ok, created_thoughts} = Neo4j.query(Nero4j.conn, created_thoughts_cypher)


    thought_resource_identifiers = Enum.map(created_thoughts, fn(thought) ->
      %{
        links: %{
          self: "http://localhost:4000/thoughts/#{thought.id}"
        },
        data: %{ type: "thoughts", id: "#{thought.id}" }
      }
    )

    res = %{
      links: %{
        self: "http://localhost:4000/api/v2/users/#{user.id}"
      },
      data: %{
        type: "users",
        id: "#{user.id}",
        attributes: %{
          username: "#{user.username}",
          email: "#{user.email}",
          user_since: "#user.created_at"
        },
        relationships: %{
          thoughts: thought_resource_identifiers
        }
      }
    }

    json conn |> put_status(200), res}
  end

  def create(conn, params) do
    %{"username" => username, "email" => email, "password" => password} = params
    # check_exists_cypher = """
    #   MATCH (user:USER)
    #   WHERE user.username = \"#{username}\" OR user.email = \"#{email}\"
    #   RETURN user;
    # """
    # {:ok, check_exists_res} = Neo4j.query(Neo4j.conn, check_exists_cypher)

    {:ok, users_with_username} = User.find(username: username)

    case length(users_with_username) do
      0 -> json conn |> put_status(201) save_user(params)
      _ -> json conn |> put_status(409) username_exists(username)
    end

    # if length(check_exists_res) == 0 do
    #   hashed_pw = Bcrypt.hashpwsalt(password)
    #   user_id = UUID.uuid1()
    #   create_user_cypher = """
    #     CREATE (user:USER {username: \"#{username}\", email: \"#{email}\",
    #       password: \"#{hashed_pw}\", id: \"#{user_id}\"})
    #     RETURN user;
    #   """
    #   {:ok, create_res} = Neo4j.tx_commit(Neo4j.conn, create_user_cypher)
    #   json conn |> put_status(201), %{"message" => create_res}
    # else
    #   json conn |> put_status(400), %{"message" => "User already exists"}
    # end
  end

  defp save_user(params) do
    %{"username" => username, "email" => email, "password" => password} = params
    {:ok, user} = User.create(username: username, email: email, password: password)

    %{
      links: %{
        self: "http://localhost:4000/api/v2/users/#{user.id}"
      },
      data: %{ type: "users", id: "#{user.id}" }
    }
  end

  defp username_exists(username) do
    %{
      errors: [%{
        status: "409",
        code: "Resource already exists",
        detail: "A user with this username already exists so they were not created."
      }]
    }
  end

end
