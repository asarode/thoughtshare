defmodule Thoughtshare.NoteController do
  use Thoughtshare.Web, :controller
  alias Thoughtshare.AuthController
  alias Neo4j.Sips, as: Neo4j
  alias Thoughtshare.GraphDB
  @validation_error %{
    errors: [%{
      status: "400",
      code: "Resource creation validation failed",
      detail: "The information passed was not valid for creating this resource."
    }]
  }
  @not_found_error %{
    errors: [%{
      status: "404",
      code: "Resource not found"
    }]
  }

  plug Guardian.Plug.EnsureAuthenticated,
    %{ on_failure: { AuthController, :unauthenticated_api }}
    when not action in [:index, :show]

  def index(conn, params) do
    %{"id" => parent_id} = params

    case GraphDB.find_group(parent_id) do
      {:ok, nil}
        -> json conn |> put_status(404), @non_found_error
      {:ok, parent}
        -> {:ok, notes} = GraphDB.find_related_notes(parent_id)
           json conn |> put_status(200), index_res(notes, parent_id)
    end
  end

  def create(conn, params) do
    optional_fields = %{"desc" => nil}
    params = Map.merge(optional_fields, params)
    %{"link" => link, "desc" => desc, "id" => parent_id} = params
    %{"id" => user_id} = Guardian.Plug.current_resource(conn)

    {:ok, parent} = GraphDB.find_group(parent_id)
    {:ok, user} = GraphDB.find_user(user_id)

    case GraphDB.create_note(link, desc, parent, user) do
      {:nok, nil, note}
        -> json conn |> put_status(400), @validation_error
      {:ok, note}
        -> json conn |> put_status(201), create_res(note)
    end
  end

  def show(conn, params) do
    %{"id" => id} = params

    case GraphDB.find_note(id) do
      {:ok, nil}
        -> json conn |> put_status(404), @not_found_error
      {:ok, note}
        -> json conn |> put_status(200), show_res(note)
    end
  end

  def update(conn, params) do
    %{"id" => id} = params
    update_fields = conn.body_params |> Map.to_list

    case GraphDB.find_note(id) do
      {:ok, nil}
        -> json conn |> put_status(404), @not_found_error
      {:ok, note}
        -> GraphDB.update_note(note, update_fields)
           {:ok, updated_note} = GraphDB.find_note(note._id)
           json conn |> put_status(200), update_res(updated_note)
    end
  end

  defp index_res(notes, parent_id) do
    note_objects = Enum.map(notes, fn(note) ->
      {:ok, note_model} = GraphDB.find_note(note["_id"])
      creator = note_model.created_by |> List.first
      %{
        type: "notes",
        id: note_model._id,
        attributes: %{
          link: note_model.link,
          desc: note_model.desc,
          created_at: note_model.created_at
        },
        relationships: %{
          creator: %{
            data: %{
              type: "users",
              id: creator._id,
              attributes: %{
                username: creator.username
              }
            }
          }
        }
      }
    end)

    %{
      links: %{
        self: "/api/v2/groups/#{parent_id}/notes",
        parent: "/api/v2/groups/#{parent_id}"
      },
      data: note_objects
    }
  end

  defp create_res(note) do
    parent = note.note_on |> List.first
    %{
      links: %{
        self: "/api/v2/notes/#{note._id}",
        parent: "/api/v2/groups/#{parent._id}"
      },
      data: %{
        type: "notes",
        id: note._id,
        attributes: %{
          link: note.link,
          desc: note.desc,
          created_at: note.created_at
        }
      }
    }
  end

  defp show_res(note) do
    creator = note.created_by |> List.first
    parent = note.note_on |> List.first
    %{
      links: %{
        self: "/api/v2/notes/#{note._id}",
        parent: "/api/v2/groups/#{parent._id}"
      },
      data: %{
        type: "notes",
        id: note._id,
        attributes: %{
          link: note.link,
          desc: note.desc,
          created_at: note.created_at
        }
      },
      relationships: %{
        creator: %{
          data: %{
            type: "users",
            id: creator._id,
            attributes: %{
              username: creator.username
            }
          }
        }
      }
    }
  end

  defp update_res(note) do
    creator = note.created_by |> List.first
    parent = note.note_on |> List.first
    %{
      links: %{
        self: "/api/v2/notes/#{note._id}",
        parent: "/api/v2/groups/#{parent._id}"
      },
      data: %{
        type: "notes",
        id: note._id,
        attributes: %{
          link: note.link,
          desc: note.desc,
          created_at: note.created_at
        }
      }
    }
  end
end
