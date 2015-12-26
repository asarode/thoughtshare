ExUnit.start

# Mix.Task.run "ecto.create", ["--quiet"]
# Mix.Task.run "ecto.migrate", ["--quiet"]
# Ecto.Adapters.SQL.begin_test_transaction(Thoughtshare.Repo)

defmodule Thoughtshare.TestUtils do
  alias Thoughtshare.GraphDB
  @title "test"
  @desc  "test"

  def gen_email(username) do
    username <> "@" <> username <> ".com"
  end

  def gen_password(username) do
    username <> "123123"
  end
end
