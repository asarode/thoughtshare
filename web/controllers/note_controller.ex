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

  plug Guardian.Plug.EnsureAuthenticated,
    %{ on_failure: { AuthController, :unauthenticated_api }}
    when not action in [:index, :show]

  def index(conn, params) do
    %{"id" => parent_id} = params

    json conn |> put_status(200), %{}
  end

  def create(conn, params) do
    %{"link" => link, "desc" => desc, "id" => parent_id} = params
    %{"id" => user_id} = Guardian.Plug.current_resource(conn)
    {:ok, user} = GraphDB.find_user(user_id)
    {:ok, group} = GraphDB.find_group(parent_id)
    case GraphDB.create_note(link, desc, group, user) do
      {:nok, nil, note}
        -> json conn |> put_status(400), @validation_error
      {:ok, note}
        -> json conn |> put_status(201), build_create_res(note, parent_id)
    end
  end

  def show(conn, params) do
    json conn |> put_status(200), %{}
  end

  def update(conn, params) do
    json conn |> put_status(200), %{}
  end

  defp build_create_res(note, parent_id) do
    id = note._id
    %{
      links: %{
        self: "/api/v2/notes/#{id}"
      },
      data: %{ type: "notes", id: id }
    }
  end
end
