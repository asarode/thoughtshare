defmodule Thoughtshare.Note do
  alias Thoughtshare.User
  alias Thoughtshare.Group
  alias Thoughtshare.ModelUtils
  use Neo4j.Sips.Model

  field :link, type: :string, required: true
  field :desc, type: :string, required: false
  field :ups, type: :integer, required: true, default: 0
  field :downs, type: :integer, required: true, default: 0
  field :_id, type: :string, required: true, default: UUID.uuid1()

  validate_with :check_desc

  relationship :CREATED_BY, User
  relationship :NOTE_ON, Group

  before_create :pre_create

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
