defmodule Thoughtshare.UserController do
  use Thoughtshare.Web, :controller
  alias Neo4j.Sips.Model.FindQueryGenerator
  alias Thoughtshare.User
  alias Thoughtshare.Cyphers
  alias Neo4j.Sips, as: Neo4j
  alias Comeonin.Bcrypt
  alias Thoughtshare.GraphDB

  def index(conn, params) do
    case params do
      %{"limit" => limit, "skip" => skip} ->
        query = FindQueryGenerator.query_with_properties(
                  User,
                  control_clauses: %{limit: limit, skip: skip})
      %{"limit" => limit} ->
        query = FindQueryGenerator.query_with_properties(
                  User,
                  control_clauses: %{limit: limit, skip: 0})
      _ ->
        query = FindQueryGenerator.query_with_properties(
                  User,
                  control_clauses: %{limit: 10, skip: 0})
    end

    {:ok, users} = Neo4j.query(Neo4j.conn, query)

    user_objects = Enum.map(users, fn(user) ->
      %{
        type: "users",
        id: user["n"]["_id"],
        attributes: %{
          username: user["n"]["username"]
        }
      }
    end)

    res = %{
      links: %{
        self: "http://localhost:4000/users"
      },
      data: user_objects
    }

    json conn |> put_status(200), res
  end

  def show(conn, %{"id" => user_id}) do
    {:ok, user} = GraphDB.find_user(user_id)

    created_thoughts_cypher = """
      MATCH (user:User {_id: \"#{user_id}\"})
      WITH user
      MATCH (user)<-[:CREATED_BY]-(thought:Thought)
      RETURN collect({id: thought._id})
    """
    {:ok, created_thoughts_raw} = Neo4j.query(Neo4j.conn, created_thoughts_cypher)

    %{"collect({id: thought._id})" => created_thoughts} = List.first(created_thoughts_raw)

    thought_resource_identifiers = Enum.map(created_thoughts, fn(thought) ->
      %{"id" => id} = thought
      %{
        links: %{
          self: "http://localhost:4000/thoughts/#{id}"
        },
        data: %{ type: "thoughts", id: "#{id}" }
      }
    end)

    res = %{
      links: %{
        self: "http://localhost:4000/api/v2/users/#{user._id}"
      },
      data: %{
        type: "users",
        id: "#{user._id}",
        attributes: %{
          username: "#{user.username}",
          email: "#{user.email}",
          user_since: "#{user.created_at}"
        },
        relationships: %{
          thoughts: thought_resource_identifiers
        }
      }
    }

    json conn |> put_status(200), res
  end

  def create(conn, params) do
    %{"username" => username, "email" => email, "password" => password} = params

    {:ok, users_with_username} = User.find(username: username)
    {:ok, users_with_email} = User.find(email: email)

    if length(users_with_username) > 0 do
      json conn |> put_status(409), user_exists("username")
    end

    if length(users_with_email) > 0 do
      json conn |> put_status(409), user_exists("email")
    end

    %{"username" => username, "email" => email, "password" => password} = params
    {:ok, user} = GraphDB.create_user(username, email, password)

    json conn |> put_status(201), user_saved(user)
  end

  def update(conn, params) do

  end

  defp user_saved(user) do
    %{
      links: %{
        self: "http://localhost:4000/api/v2/users/#{user._id}"
      },
      data: %{ type: "users", id: "#{user._id}" }
    }
  end

  defp user_exists(field) do
    %{
      errors: [%{
        status: "409",
        code: "Resource already exists",
        detail: "A user with this #{field} already exists so they were not created."
      }]
    }
  end

end
