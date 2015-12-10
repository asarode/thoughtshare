defmodule Thoughtshare.Note do
  alias Thoughtshare.User
  alias Thoughtshare.Group
  use Neo4j.Sips.Model

  field :link, type: :string, required: true
  field :desc, type: :string, required: false
  field :ups, type: :integer, required: true, default: 0
  field :downs, type: :integer, required: true, default: 0
  field :created_at, type: :integer, required: true, default: :os.system_time(:seconds)

  validate_with :check_desc

  relationship :CREATED_BY, User
  relationship :NOTE_ON, Group

  def check_desc(model) do
    if (String.length(model.desc) > 200) do
      {:desc, "model.validation.invalid_desc"}
    end
  end
end
