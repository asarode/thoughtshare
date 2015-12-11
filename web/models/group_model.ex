defmodule Thoughtshare.Group do
  use Neo4j.Sips.Model
  alias Thoughtshare.User
  alias Thoughtshare.ModelUtils

  field :title, type: :string, required: true
  field :desc, type: :string, required: false
  field :_id, type: :string, required: true, default: UUID.uuid1()

  validate_with :check_title
  validate_with :check_desc

  relationship :CREATED_BY, User
  relationship :GROUP_ON, Group

  before_create :pre_create

  def check_title(model) do
    if (String.length(model.title) > 110) do
      {:title, "model.validation.invalid_title"}
    end
  end

  def check_desc(model) do
    if (String.length(model.desc) > 200) do
      {:desc, "model.validation.invalid_desc"}
    end
  end

  def pre_create(model) do
    model
    |> ModelUtils.add_uuid
  end
end
