defmodule Thoughtshare.GroupControllerTest do
  use ExUnit.Case, async: false
  use Plug.Test
  alias Thoughtshare.GraphDB
  alias Thoughtshare.TestUtils
  @title     "test"
  @title_mod "testtest"
  @desc      "test"
  @desc_mod  "testtest"

  setup do
    on_exit fn ->
      GraphDB.clear()
    end
  end

  test "GET /groups/:id/groups returns a list of groups" do
    username = "879yvuvft"
    email = TestUtils.gen_email(username)
    password = TestUtils.gen_password(username)
    {:ok, user} = GraphDB.create_user(username, email, password)
    {:ok, thought} = GraphDB.create_thought(@title, @desc, user)
    {:ok, group} = GraphDB.create_group(@title, @desc, thought, user)

    response = conn(:get, "/api/v2/groups/#{thought._id}/groups")
      |> send_request

    assert %{
      "links" => %{
        "self" => self_link,
        "parent" => parent_link
      },
      "data" => [%{
        "type" => "groups",
        "id" => id,
        "attributes" => %{
          "title" => title,
          "desc" => desc,
          "created_at" => created_at
        }
      }]
    } = Poison.decode!(response.resp_body), "Invalid response body"

    assert self_link == "/api/v2/groups/#{thought._id}/groups", "Invalid self link"
    assert parent_link == "/api/v2/groups/#{thought._id}", "Invalid parent link"
    assert id == group._id, "Invalid id"
    assert title == group.title, "Invalid title"
    assert desc == group.desc, "Invalid desc"
    assert created_at == group.created_at, "Invalid created_at"
    assert response.status == 200
    assert response.state == :sent
  end

  test "POST /groups/:id/groups creates a group" do
    username = "asdf"
    email = TestUtils.gen_email(username)
    password = TestUtils.gen_password(username)
    {:ok, user} = GraphDB.create_user(username, email, password)
    {:ok, token, _} = Guardian.encode_and_sign(user, :token)
    {:ok, thought} = GraphDB.create_thought(@title, @desc, user)

    post_body = %{
      title: @title,
      desc: @desc
    }
    response = conn(:post, "/api/v2/groups/#{thought._id}/groups", post_body)
      |> put_req_header("authorization", token)
      |> send_request

    assert %{
      "links" => %{
        "self" => self_link,
        "parent" => parent_link,
        "groups" => groups_link,
        "notes" => notes_link
      },
      "data" => %{
        "type" => "groups",
        "id" => id,
        "attributes" => %{
          "title" => title,
          "desc" => desc,
          "created_at" => created_at
        }
      }
    } = Poison.decode!(response.resp_body), "Invalid response body"

    {:ok, group} = GraphDB.find_group(id)

    assert self_link == "/api/v2/groups/#{group._id}", "Invalid self link"
    assert parent_link == "/api/v2/groups/#{thought._id}", "Invalid parent link"
    assert groups_link == "/api/v2/groups/#{group._id}/groups", "Invalid groups link"
    assert notes_link == "/api/v2/groups/#{group._id}/notes", "Invalid notes link"
    assert id == group._id, "Invalid id"
    assert title == group.title, "Invalid title"
    assert desc == group.desc, "Invalid desc"
    assert created_at == group.created_at, "Invalid created_at"
    assert response.status == 201
    assert response.state == :sent
  end

  test "GET /groups/:id gets a specific group" do
    username = "tg93hgpib"
    email = TestUtils.gen_email(username)
    password = TestUtils.gen_password(username)
    {:ok, user} = GraphDB.create_user(username, email, password)
    {:ok, group} = GraphDB.create_thought(@title, @desc, user)

    response = conn(:get, "/api/v2/groups/#{group._id}")
      |> send_request

    assert %{
      "links" => %{
        "self" => self_link,
        "groups" => groups_link,
        "notes" => notes_link
      },
      "data" => %{
        "type" => "groups",
        "id" => id,
        "attributes" => %{
          "title" => title,
          "desc" => desc,
          "created_at" => created_at
        },
        "relationships" => %{
          "creator" => %{
            "data" => %{
              "type" => "users",
              "id" => user_id,
              "attributes" => %{
                "username" => username
              }
            }
          }
        }
      }
    } = Poison.decode!(response.resp_body), "Invalid response body"

    assert self_link == "/api/v2/groups/#{group._id}", "Invalid self link"
    assert groups_link == "/api/v2/groups/#{group._id}/groups", "Invalid groups link"
    assert notes_link == "/api/v2/groups/#{group._id}/notes", "Invalid notes link"
    assert id == group._id, "Invalid id"
    assert title == group.title, "Invalid title"
    assert desc == group.desc, "Invalid desc"
    assert created_at == group.created_at, "Invalid created_at"
    assert user_id == user._id, "Invalid creator id"
    assert username == user.username, "Invalid creator username"
    assert response.status == 200
    assert response.state == :sent
  end

  test "PUT /groups/:id updates a specific group" do
    username = "asdf"
    email = TestUtils.gen_email(username)
    password = TestUtils.gen_password(username)
    {:ok, user} = GraphDB.create_user(username, email, password)
    {:ok, token, _} = Guardian.encode_and_sign(user, :token)
    {:ok, group} = GraphDB.create_thought(@title, @desc, user)

    put_body = %{
      title: @title_mod,
      desc: @desc_mod
    }
    response = conn(:put, "/api/v2/groups/#{group._id}", put_body)
      |> put_req_header("authorization", token)
      |> send_request

    {:ok, updated_group} = GraphDB.find_group(group._id)

    assert updated_group.title == @title_mod, "Group title not updated correctly in database"
    assert updated_group.desc == @desc_mod, "Group desc not updated correctly in database"

    assert %{
      "links" => %{
        "self" => self_link,
        "groups" => groups_link,
        "notes" => notes_link
      },
      "data" => %{
        "type" => "groups",
        "id" => id,
        "attributes" => %{
          "title" => title,
          "desc" => desc,
          "created_at" => created_at
        }
      }
    } = Poison.decode!(response.resp_body), "Invalid response body"

    assert self_link == "/api/v2/groups/#{group._id}", "Invalid self link"
    assert groups_link == "/api/v2/groups/#{group._id}/groups", "Invalid groups link"
    assert notes_link == "/api/v2/groups/#{group._id}/notes", "Invalid notes link"
    assert id == updated_group._id, "Invalid id"
    assert title == updated_group.title, "Invalid title"
    assert desc == updated_group.desc, "Invalid desc"
    assert created_at == updated_group.created_at, "Invalid created_at"
    assert response.status == 200
    assert response.state == :sent
  end

  defp send_request(conn) do
    conn
    |> put_private(:plug_skip_csrf_protection, true)
    |> Thoughtshare.Endpoint.call([])
  end
end
