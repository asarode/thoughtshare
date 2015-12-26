defmodule Thoughtshare.ThoughtControllerTest do
  use ExUnit.Case, async: false
  use Plug.Test
  alias Thoughtshare.GraphDB
  @title    "test"
  @desc     "test"

  setup do
    on_exit fn ->
      GraphDB.clear()
    end
  end

  # test "/thoughts returns a list of thought object identifiers" do
  #   username = "asarode"
  #   email = gen_email(username)
  #   password = gen_password(username)
  #   user = create_test_user(username, email, password)
  #   thought = create_test_thought(user)
  #
  #   response = conn(:get, "/api/v2/thoughts") |> send_request
  #
  #   expected_res = %{
  #     links: %{
  #       self: "http://localhost:4000/api/v2/thoughts?limit=\"10\"&skip=\"0\""
  #     },
  #     data: [%{
  #       type: "thoughts",
  #       id: thought._id,
  #       attributes: %{
  #         title: @title,
  #         desc: @desc
  #       }
  #     }]
  #   }
  #   |> Poison.encode!
  #
  #   assert response.resp_body == expected_res
  #   assert response.status == 200
  #   assert response.state == :sent
  # end

  # test "/thougths/:id returns a specific thought resource" do
  #   user = context[:user]
  #   {:ok, thought} = create_test_thought(user)
  #
  #   response = conn(:get, "/api/v2/thoughts/#{thought._id}")  |> send_request
  #
  #   expected_res = %{
  #     links: %{
  #       self: "http://localhost:4000/api/v2/thoughts/#{thought._id}"
  #     },
  #     data: %{
  #       type: "thoughts",
  #       id: though._id,
  #       attributes: %{
  #         title: @title,
  #         desc: @desc
  #       },
  #       relationships: %{
  #         creator: %{
  #           data: %{
  #             type: "users",
  #             id: user._id,
  #             attributes: %{
  #               username: @username
  #             }
  #           }
  #         },
  #         notes: %{
  #           data: note_objects
  #         },
  #         groups: %{
  #           data: group_objects
  #         }
  #       }
  #     }
  #   }
  #
  #   assert response.status == 200
  #   assert response.state == :sent
  # end

  defp send_request(conn) do
    conn
    |> put_private(:plug_skip_csrf_protection, true)
    |> Thoughtshare.Endpoint.call([])
  end

  defp create_test_user(username, email, password) do
    {:ok, user} = GraphDB.create_user(username, email, password)
    user
  end

  defp create_test_thought(user) do
    {:ok, thought} = GraphDB.create_thought(@title, @desc, user)
    thought
  end

  defp gen_email(username) do
    username <> "@" <> username <> ".com"
  end

  defp gen_password(username) do
    username <> "123123"
  end
end
