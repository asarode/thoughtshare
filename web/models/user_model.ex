defmodule Thoughtshare.User do
  use Neo4j.Sips.Model
  alias Comeonin.Bcrypt

  field :username, type: :string, required: true, unique: true
  field :email, type: :string, required: true, unique: true, format: ~r/\b[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,4}\b/
  field :password, type: :string, required: true
  field :id, type: :string, required: true, default: UUID.uuid1()
  field :created_at type: :integer, required: true, default: :os.system_time(:seconds)

  validate_with :check_username

  before_save :hash_password

  def check_username(model) do
    if (String.length(model.username) > 25) do
      {:username, "model.validation.invalid_username"}
    end
  end

  def hash_password(model) do
    hashed_pw = Bcrypt.hashpwsalt(model.password)
    Map.put(model, :password, hashed_pw)
  end
end
