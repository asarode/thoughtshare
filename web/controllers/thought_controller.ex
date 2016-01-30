defmodule Thoughtshare.ThoughtController do
  use Thoughtshare.Web, :controller
  alias Thoughtshare.AuthController
  alias Neo4j.Sips, as: Neo4j
  alias Thoughtshare.GraphDB

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
    {:ok, thoughts} = GraphDB.find_thought_list(limit, skip)

    IO.inspect thoughts
    thought_objects = Enum.map(thoughts, fn(thought) ->
      %{
        type: "thoughts",
        id: thought["_id"],
        attributes: %{
          title: thought["title"],
          desc: thought["desc"],
          created_at: thought["created_at"]
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

    %{"id" => user_id} = Guardian.Plug.current_resource(conn)
    {:ok, user} = GraphDB.find_user(user_id)
    create_res = GraphDB.create_thought(title, desc, user)
    case create_res do
      {:nok, nil, thought}
        -> json conn |> put_status(400), validation_error()
      {:ok, thought}
        -> json conn |> put_status(201), build_create_res(thought)
    end
  end

  @doc """
  Returns a thought resource object with a list of groups and notes underneath
  it. The groups and notes are returned as object identifiers.
  """
  def show(conn, params) do
    %{"id" => id} = params
    {:ok, thought_model} = GraphDB.find_thought(id)

    case thought_model do
      nil
        -> json conn |> put_status(404), not_found_error()
      _ 
        -> 
          {:ok, related} = GraphDB.find_related(thought_model)
          res = Map.merge(related, %{"thought" => thought_model})
          |> show_res
    end

    json conn |> put_status(200), res
  end

  @doc """
  Updates a thought's title and/or description. Returns a thought object
  identifier for the updated resource.
  """
  def update(conn, params) do
    %{"id" => id} = params
    update_fields = conn.body_params |> Map.to_list

    case GraphDB.find_thought(id) do
      {:ok, nil}
        -> json conn |> put_status(404), @not_found_error
      {:ok, thought_model}
        ->
          GraphDB.update_thought(thought_model, update_fields)
          {:ok, updated_thought_model} = GraphDB.find_thought(thought_model._id)
          json conn |> put_status(200), update_res(updated_thought_model)
    end
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

  defp not_found_error() do
    %{
      errors: [%{
        status: "404",
        code: "Resource not found"
      }]
    }
  end

  defp build_create_res(thought) do
    id = thought._id
    %{
      links: %{
        self: "http://localhost:4000/api/v2/thoughts/#{id}"
      },
      data: %{ type: "thoughts", id: id }
    }
  end

  defp build_resource_identifier(objects, type) do
    Enum.map(objects, fn(object) ->
      %{
        type: type,
        id: object["_id"]
      }
    end)
  end

  defp show_res(related) do
    %{"thought" => thought_model, "notes" => notes, "groups" => groups} = related
    creator_model = thought_model.created_by |> List.first

    %{
      links: %{
        self: "http://localhost:4000/api/v2/thoughts/#{thought_model._id}"
      },
      data: %{
        type: "thoughts",
        id: thought_model._id,
        attributes: %{
          title: thought_model.title,
          desc: thought_model.desc,
          created_at: thought_model.created_at
        },
        relationships: %{
          creator: %{
            data: %{
              type: "users",
              id: creator_model._id,
              attributes: %{
                username: creator_model.username
              }
            }
          },
          notes: %{
            data: build_resource_identifier(notes, "notes")
          },
          groups: %{
            data: build_resource_identifier(groups, "groups")
          }
        }
      }
    }
  end

  defp update_res(thought_model) do
    %{
      links: %{
        self: "/api/v2/thoughts/#{thought_model._id}",
        groups: "/api/v2/groups/#{thought_model._id}/groups",
        notes: "/api/v2/groups/#{thought_model._id}/notes"
      },
      data: %{
        type: "thoughts",
        id: thought_model._id,
        attributes: %{
          title: thought_model.title,
          desc: thought_model.desc,
          created_at: thought_model.created_at
        }
      }
    }
  end
end
