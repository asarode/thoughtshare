defmodule Thoughtshare.GuardianSerializer do
  @behavior Guardian.Serializer
  alias Thoughtshare.Cyphers
  alias Neo4j.Sips, as: Neo4j
  alias Poison.Parser

  def for_token(user) do
    %{"id" => id, "email" => email, "username" => username} = user

    {:ok, Poison.encode!(%{id: id, email: email, username: username})}
  end
  # def for_token(_), do: {:error, "Unknown resource type"}

  def from_token(user) do
    {:ok, Poison.decode!(user)}
  end
  def from_token(_), do: {:error, "Unknown resource type"}

end
