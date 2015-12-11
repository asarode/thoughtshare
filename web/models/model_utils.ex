defmodule Thoughtshare.ModelUtils do
  def add_uuid(model) do
    Map.put(model, :_id, UUID.uuid1())
  end
end
