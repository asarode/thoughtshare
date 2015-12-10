defmodule Thoughtshare.Group do
  alias Thoughtshare.User
  use Neo4j.Sips.Model

  field :title, type: :string, required: true
  field :desc, type: :string, required: false
  field :id, type: :string, required: true, default: UUID.uuid1()
  field :created_at, type: :integer, required: true, default: :os.system_time(:seconds)

  validate_with :check_title
  validate_with :check_desc

  relationship :CREATED_BY, User
  relationship :GROUP_ON, Group

  def check_title(model) do
    if (String.length(mode.title) > 110) do
      {:title, "model.validation.invalid_title"}
    end
  end

  def check_desc(model) do
    if (String.length(model.desc) > 200) do
      {:desc, "model.validation.invalid_desc"}
    end
  end
end
