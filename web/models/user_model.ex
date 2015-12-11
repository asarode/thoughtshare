defmodule Thoughtshare.User do
  use Neo4j.Sips.Model
  alias Comeonin.Bcrypt
  alias Thoughtshare.ModelUtils

  field :username, type: :string, required: true, unique: true
  field :email, type: :string, required: true, unique: true, format: ~r/\b[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,4}\b/
  field :password, type: :string, required: true
  field :_id, type: :string

  validate_with :check_username

  before_create :pre_create

  def check_username(model) do
    if (String.length(model.username) > 25) do
      {:username, "model.validation.invalid_username"}
    end
  end

  def hash_password(model) do
    hashed_pw = Bcrypt.hashpwsalt(model.password)
    Map.put(model, :password, hashed_pw)
  end

  def add_uuid(model) do
    Map.put(model, :_id, UUID.uuid1())
  end

  def pre_create(model) do
    model
    |> hash_password
    |> ModelUtils.add_uuid
  end
end
