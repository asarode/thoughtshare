defmodule Thoughtshare.ModelUtils do
  def add_uuid(model) do
    Map.put(model, :_id, UUID.uuid1())
  end

  def check_title(model) do
    if (String.length(model.title) > 110) do
      {:title, "model.validation.invalid_title"}
    else
      model
    end
  end

  def check_desc(model) do
    if (Map.has_key?(model, :desc) and String.length(model.desc) > 200) do
      {:desc, "model.validation.invalid_desc"}
    else
      model
    end
  end
end
