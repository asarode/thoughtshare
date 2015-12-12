defmodule Thoughtshare.Thought do
  use Neo4j.Sips.Model
  alias Thoughtshare.User
  alias Thoughtshare.ModelUtils

  field :title, type: :string, required: true
  field :desc, type: :string, required: false
  field :_id, type: :string, required: true, default: "0"

  validate_with :check_title
  validate_with :check_desc

  relationship :CREATED_BY, User

  before_create :pre_create

  def check_title(model) do
    ModelUtils.check_title(model)
  end

  def check_desc(model) do
    ModelUtils.check_desc(model)
  end

  def pre_create(model) do
    ModelUtils.add_uuid(model)
  end

end
