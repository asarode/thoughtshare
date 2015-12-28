defmodule Thoughtshare.GroupController do
  use Thoughtshare.Web, :controller
  alias Thoughtshare.AuthController
  alias Neo4j.Sips, as: Neo4j
  alias Thoughtshare.GraphDB
  alias Plug.Conn
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
        -> json conn |> put_status(404), @not_found_error
      {:ok, parent}
        -> {:ok, groups} = GraphDB.find_related_groups(parent_id)
           json conn |> put_status(200), index_res(groups, parent_id)
    end
  end

  def create(conn, params) do
    optional_fields = %{"desc" => nil}
    params = Map.merge(optional_fields, params)
    %{"id" => parent_id, "title" => title, "desc" => desc} = params
    %{"id" => user_id} = Guardian.Plug.current_resource(conn)

    {:ok, parent} = GraphDB.find_group(parent_id)
    {:ok, user} = GraphDB.find_user(user_id)

    case GraphDB.create_group(title, desc, parent, user) do
      {:nok, nil, group}
        -> json conn |> put_status(400), @validation_error
      {:ok, group}
        -> json conn |> put_status(201), create_res(group)
    end
  end

  def show(conn, params) do
    %{"id" => id} = params

    case GraphDB.find_group(id) do
      {:ok, nil}
        -> json conn |> put_status(404), @not_found_error
      {:ok, group}
        -> json conn |> put_status(200), show_res(group)
    end
  end

  def update(conn, params) do
    %{"id" => id} = params
    update_fields = conn.body_params |> Map.to_list

    case GraphDB.find_group(id) do
      {:ok, nil}
        -> json conn |> put_status(404), @not_found_error
      {:ok, group}
        -> GraphDB.update_group(group, update_fields)
           {:ok, updated_group} = GraphDB.find_group(group._id)
           json conn |> put_status(200), update_res(updated_group)
    end
  end

  defp get_update_params(params) do

    Enum.filter(params, fn({key, _}) ->
      key != "id"
    end)
  end

  defp index_res(groups, parent_id) do
    group_objects = Enum.map(groups, fn(group) ->
      %{
        type: "groups",
        id: group["_id"],
        attributes: %{
          title: group["title"],
          desc: group["desc"],
          created_at: group["created_at"]
        }
      }
    end)

    %{
      links: %{
        self: "/api/v2/groups/#{parent_id}/groups",
        parent: "/api/v2/groups/#{parent_id}",
        notes: "/api/v2/groups/#{parent_id}/notes"
      },
      data: group_objects
    }
  end

  defp create_res(group) do
    parent = group.group_on |> List.first
    %{
      links: %{
        self: "/api/v2/groups/#{group._id}",
        parent: "/api/v2/groups/#{parent._id}",
        groups: "/api/v2/groups/#{group._id}/groups",
        notes: "/api/v2/groups/#{group._id}/notes"
      },
      data: %{
        type: "groups",
        id: group._id,
        attributes: %{
          title: group.title,
          desc: group.desc,
          created_at: group.created_at
        }
      }
    }
  end

  defp show_res(group) do
    creator = group.created_by |> List.first
    %{
      links: %{
        self: "/api/v2/groups/#{group._id}",
        groups: "/api/v2/groups/#{group._id}/groups",
        notes: "/api/v2/groups/#{group._id}/notes"
      },
      data: %{
        type: "groups",
        id: group._id,
        attributes: %{
          title: group.title,
          desc: group.desc,
          created_at: group.created_at
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
    }
  end

  defp update_res(group) do
    %{
      links: %{
        self: "/api/v2/groups/#{group._id}",
        groups: "/api/v2/groups/#{group._id}/groups",
        notes: "/api/v2/groups/#{group._id}/notes"
      },
      data: %{
        type: "groups",
        id: group._id,
        attributes: %{
          title: group.title,
          desc: group.desc,
          created_at: group.created_at
        }
      }
    }
  end
end
