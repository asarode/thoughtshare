defmodule Thoughtshare.NoteControllerTest do
  use ExUnit.Case, async: false
  use Plug.Test
  alias Thoughtshare.GraphDB
  alias Thoughtshare.TestUtils
  @title    "test"
  @link     "http://arjunsarode.com"
  @link_mod "http://arjun.ink"
  @desc     "test"
  @desc_mod "testtest"

  setup do
    on_exit fn ->
      GraphDB.clear()
    end
  end

  test "GET /groups/:id/notes returns a list of notes" do
    username = "a90sucsdjovb"
    email = TestUtils.gen_email(username)
    password = TestUtils.gen_password(username)
    {:ok, user} = GraphDB.create_user(username, email, password)
    {:ok, thought} = GraphDB.create_thought(@title, @desc, user)
    {:ok, group} = GraphDB.find_group(thought._id)
    {:ok, note} = GraphDB.create_note(@link, @desc, group, user)

    response = conn(:get, "/api/v2/groups/#{group._id}/notes")
      |> send_request

    assert %{
      "links" => %{
        "self" => self_link,
        "parent" => parent_link
      },
      "data" => [%{
        "type" => "notes",
        "id" => id,
        "attributes" => %{
          "link" => link,
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
      }]
    } = Poison.decode!(response.resp_body), "Invalid response body"

    assert self_link == "/api/v2/groups/#{group._id}/notes", "Invalid self link"
    assert parent_link == "/api/v2/groups/#{group._id}", "Invalid parent link"
    assert id == note._id, "Invalid id"
    assert link == note.link, "Invalid title"
    assert desc == note.desc, "Invalid desc"
    assert created_at == note.created_at, "Invalid created_at"
    assert user_id == user._id, "Invalid creator id"
    assert username == user.username, "Invalid creator username"
    assert response.status == 200
    assert response.state == :sent
  end

  test "POST /groups/:id/notes creates a note" do
    username = "tabun"
    email = TestUtils.gen_email(username)
    password = TestUtils.gen_password(username)
    {:ok, user} = GraphDB.create_user(username, email, password)
    {:ok, token, _} = Guardian.encode_and_sign(user, :token)
    {:ok, thought} = GraphDB.create_thought(@title, @desc, user)

    thought_id = thought._id
    post_body = %{
      link: @link,
      desc: @desc
    }
    response = conn(:post, "/api/v2/groups/#{thought_id}/notes", post_body)
      |> put_req_header("authorization", token)
      |> send_request

    assert %{
      "links" => %{
        "self" => self_link,
        "parent" => parent_link
      },
      "data" => %{
        "type" => "notes",
        "id" => id,
        "attributes" => %{
          "link" => link,
          "desc" => desc,
          "created_at" => created_at
        }
      }
    } = Poison.decode!(response.resp_body), "Invalid response body"

    {:ok, note} = GraphDB.find_note(id)

    assert self_link == "/api/v2/notes/#{note._id}", "Invalid self link"
    assert parent_link == "/api/v2/groups/#{thought._id}", "Invalid parent link"
    assert id == note._id, "Invalid id"
    assert link == note.link, "Invalid title"
    assert desc == note.desc, "Invalid desc"
    assert created_at == note.created_at, "Invalid created_at"
    assert response.status == 201
    assert response.state == :sent
  end

  test "GET /notes/:id gets a specific note" do
    username = "af2v2vv2r"
    email = TestUtils.gen_email(username)
    password = TestUtils.gen_password(username)
    {:ok, user} = GraphDB.create_user(username, email, password)
    {:ok, token, _} = Guardian.encode_and_sign(user, :token)
    {:ok, thought} = GraphDB.create_thought(@title, @desc, user)
    {:ok, note} = GraphDB.create_note(@link, @desc, thought, user)

    response = conn(:get, "/api/v2/notes/#{note._id}")
      |> send_request

    assert %{
      "links" => %{
        "self" => self_link,
        "parent" => parent_link
      },
      "data" => %{
        "type" => "notes",
        "id" => id,
        "attributes" => %{
          "link" => link,
          "desc" => desc,
          "created_at" => created_at
        }
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
    } = Poison.decode!(response.resp_body), "Invalid response body"

    assert self_link == "/api/v2/notes/#{note._id}", "Invalid self link"
    assert parent_link == "/api/v2/groups/#{thought._id}", "Invalid parent link"
    assert id == note._id, "Invalid id"
    assert link == note.link, "Invalid link"
    assert desc == note.desc, "Invalid desc"
    assert created_at == note.created_at, "Invalid created at"
    assert user_id == user._id, "Invalid creator id"
    assert username == user.username, "Invalid creator username"
    assert response.status == 200
    assert response.state == :sent
  end

  test "PUT /notes/:id updated a specific group" do
    username = "a0fu09vsaovw"
    email = TestUtils.gen_email(username)
    password = TestUtils.gen_password(username)
    {:ok, user} = GraphDB.create_user(username, email, password)
    {:ok, token, _} = Guardian.encode_and_sign(user, :token)
    {:ok, thought} = GraphDB.create_thought(@title, @desc, user)
    {:ok, note} = GraphDB.create_note(@link, @desc, thought, user)

    put_body = %{
      link: @link_mod,
      desc: @desc_mod
    }
    response = conn(:put, "/api/v2/notes/#{note._id}", put_body)
      |> put_req_header("authorization", token)
      |> send_request

    {:ok, updated_note} = GraphDB.find_note(note._id)

    assert updated_note.link == @link_mod, "Note link not updated correctly in database"
    assert updated_note.desc == @desc_mod, "Note desc not updated correctly in database"

    assert %{
      "links" => %{
        "self" => self_link,
        "parent" => parent_link
      },
      "data" => %{
        "type" => "notes",
        "id" => id,
        "attributes" => %{
          "link" => link,
          "desc" => desc,
          "created_at" => created_at
        }
      }
    } = Poison.decode!(response.resp_body), "Invalid response body"

    assert self_link == "/api/v2/notes/#{note._id}", "Invalid self link"
    assert parent_link == "/api/v2/groups/#{thought._id}", "Invalid parent link"
    assert id == updated_note._id, "Invalid id"
    assert link == updated_note.link, "Invalid link"
    assert desc == updated_note.desc, "Invalid desc"
    assert created_at == updated_note.created_at, "Invalid created_at"
    assert response.status == 200
    assert response.state == :sent
  end

  defp send_request(conn) do
    conn
    |> put_private(:plug_skip_csrf_protection, true)
    |> Thoughtshare.Endpoint.call([])
  end
end
