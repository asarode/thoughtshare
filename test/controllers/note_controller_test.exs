defmodule Thoughtshare.NoteControllerTest do
  use ExUnit.Case, async: false
  use Plug.Test
  alias Thoughtshare.GraphDB
  alias Thoughtshare.TestUtils
  @title    "test"
  @desc     "test"
  @link     "http://arjunsarode.com"

  setup do
    on_exit fn ->
      GraphDB.clear()
    end
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

    %{"data" => %{"id" => note_id}} = Poison.decode!(response.resp_body)
    {:ok, note} = GraphDB.find_note(note_id)

    refute note == nil, "Note creation failed"
    assert response.status == 201
    assert response.state == :sent
  end

  defp send_request(conn) do
    conn
    |> put_private(:plug_skip_csrf_protection, true)
    |> Thoughtshare.Endpoint.call([])
  end
end
