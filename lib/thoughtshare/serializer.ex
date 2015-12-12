defmodule Thoughtshare.GuardianSerializer do
  @behavior Guardian.Serializer
  alias Thoughtshare.Cyphers
  alias Neo4j.Sips, as: Neo4j
  alias Poison.Parser

  def for_token(user) do
    {:ok, Poison.encode!(%{id: user._id, email: user.email, username: user.username})}
  end
  # def for_token(_), do: {:error, "Unknown resource type"}

  def from_token(user) do
    # {:ok, Poison.decode!(user)}
    {:ok, %{id: user["id"], email: user["email"], username: user["username"]}}
  end
  # def from_token(_), do: {:error, "Unknown resource type"}
end
