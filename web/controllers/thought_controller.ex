defmodule Thoughtshare.ThoughtController do
  use Thoughtshare.Web, :controller
  alias Thoughtshare.AuthController
  alias Thoughtshare.Cyphers
  alias Thoughtshare.Group
  alias Thoughtshare.Thought
  alias Thoughtshare.User
  alias Neo4j.Sips, as: Neo4j
  alias Posion.Parser

  plug Guardian.Plug.EnsureAuthenticated,
    %{ on_failure: { AuthController, :unauthenticated_api }}
    when not action in [:index, :show]

  @doc """
  Returns a list of thought resource objects. Be default the list is limitted
  to 10. You can add `limit` and `skip` params to control pagination of the
  returned data.
  """
  def index(conn, params) do
    defaultControls = %{"limit" => 10, "skip" => 0}
    %{"limit" => limit, "skip" => skip} = Map.merge(defaultControls, params)
    query = find_thought_list(limit, skip)

    {:ok, thoughts} = Neo4j.query(Neo4j.conn, query)

    thought_objects = Enum.map(thoughts, fn(thought) ->
      %{
        type: "thoughts",
        id: get_thought_query_field(thought, "_id"),
        attributes: %{
          title: get_thought_query_field(thought, "title"),
          desc: get_thought_query_field(thought, "desc")
        }
      }
    end)

    res = %{
      links: %{
        self: "http://localhost:4000/api/v2/thoughts?limit=\"#{limit}\"&skip=\"#{skip}\""
      },
      data: thought_objects
    }

    json conn |> put_status(200), res
  end

  @doc """
  Creates a new thought resource object and returns a thought object idenfier
  for the created resource. Returns a 400 if validation for creating the thought
  fails.
  """
  def create(conn, params) do
    %{"title" => title, "desc" => desc} = params

    %{id: user_id} = Guardian.Plug.current_resource(conn)
    {:ok, user} = User.find(_id: user_id)
    create_res = Thought.create(title: title, desc: desc, created_by: user)
    case create_res do
      {:nok, nil, thought} -> json conn |> put_status(400), validation_error()
      {:ok, thought} ->
        res = thought
              |> add_group_label
              |> build_create_res
    end

    json conn |> put_status(201), res
  end

  @doc """
  Returns a thought resource object with a list of groups and notes underneath
  it. The groups and notes are returned as object identifiers.
  """
  def show(conn, params) do

  end

  @doc """
  Updates a thought's title and/or description. Returns a thought object
  identifier for the updated resource.
  """
  def update(conn, params) do

  end

  defp find_thought_list(limit, skip) do
    """
    MATCH (n:Thought)
    RETURN n
    LIMIT #{limit}
    SKIP #{skip};
    """
  end

  defp get_thought_query_field(thought, field) do
    thought["n"]["#{field}"]
  end

  defp add_group_label(thought) do
    id = thought._id
    query = """
    MATCH (n:Thought {_id: \"#{id}\"})
    SET n :Group
    return n;
    """
    List.first(Neo4j.query!(Neo4j.conn, query))
  end

  defp validation_error() do
    %{
      errors: [%{
        status: "400",
        code: "Resource creation validation failed",
        detail: "The information passed was not valid for creating this resource."
      }]
    }
  end

  defp build_create_res(thought) do
    id = get_thought_query_field(thought, "_id")
    IO.inspect thought
    %{
      links: %{
        self: "http://localhost:4000/api/v2/thoughts/#{id}"
      },
      data: %{ type: "thoughts", id: id }
    }
  end
end
