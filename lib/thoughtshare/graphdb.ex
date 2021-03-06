defmodule Thoughtshare.GraphDB do
  @t "thought_node"
  @g "group_note"
  @n "note_node"
  @u "user_node"
  alias Neo4j.Sips, as: Neo4j
  alias Thoughtshare.Thought
  alias Thoughtshare.Group
  alias Thoughtshare.Note
  alias Thoughtshare.User

  # def get_thought_field(thought, field) do
  #   get_field(thought, field, :thought)
  # end
  #
  # def get_group_field(group, field) do
  #   get_field(group, field, :group)
  # end
  #
  # def get_note_field(note, field) do
  #   get_field(note, field, :note)
  # end
  #
  # def get_user_field(user, field) do
  #   get_field(user, field, :user)
  # end
  #
  # def get_field(object, field, type) do
  #   case type do
  #     :thought -> type = @t
  #     :group   -> type = @g
  #     :note    -> type = @n
  #     :user    -> type = @u
  #   end
  #   object[type][field]
  # end

  def find_thought(id) do
    find(Thought, id)
  end

  def find_group(id) do
    find(Group, id)
  end

  def find_note(id) do
    find(Note, id)
  end

  def find_user(id) do
    find(User, id)
  end

  def find(model, id) do
    model.find(_id: id) |> unwrap_query
  end

  def create_thought(title, desc, user) do
    case Thought.create(title: title, desc: desc, created_by: user) do
      {:nok, nil, thought}
        -> {:nok, nil, thought}
      {:ok, thought}
        -> {:ok, thought} = append_group_label(thought) |> unwrap_query |> unlabel_query
           find(Thought, thought["_id"])
    end
  end

  def create_group(title, desc, group, user) do
    Group.create(title: title, desc: desc, group_on: group, created_by: user)
  end

  def create_note(link, desc, group, user) do
    Note.create(link: link, desc: desc, note_on: group, created_by: user)
  end

  def create_user(username, email, password) do
    User.create(username: username, email: email, password: password)
  end

  def update_group(group, fields) do
    update(Group, group, fields)
  end

  def update_note(note, fields) do
    update(Note, note, fields)
  end

  def update(model, object, fields) do
    model.update(object, fields)
  end

  def find_thought_list(limit, skip) do
    query = find_thought_list_cypher(limit, skip)
    {:ok, thoughts} = Neo4j.query(Neo4j.conn, query)
    thoughts = Enum.map(thoughts, fn(thought) ->
      thought |> unlabel_query
    end)
    {:ok, thoughts}
  end

  def append_group_label(thought) do
    query = append_group_label_cypher(thought._id)
    Neo4j.query(Neo4j.conn, query)
  end

  def find_related(id) do
    {:ok, groups} = find_related_groups(id)
    {:ok, notes} = find_related_notes(id)
    {:ok, %{"groups" => groups, "notes" => notes}}
  end

  def find_related_groups(parent_id) do
    query = find_related_groups_cypher(parent_id)
    Neo4j.query(Neo4j.conn, query) |> unwrap_query |> unlabel_query
  end

  def find_related_notes(parent_id) do
    query = find_related_notes_cypher(parent_id)
    Neo4j.query(Neo4j.conn, query) |> unwrap_query |> unlabel_query
  end

  def find_parent(self_id) do
    query = find_parent_cypher(self_id)
    IO.inspect Neo4j.query(Neo4j.conn, query)
    case Neo4j.query(Neo4j.conn, query) do
      {:ok, []}
        -> {:ok, nil}
      parent
        -> parent |> unwrap_query |> unlabel_query
    end
  end

  def unwrap_query({:ok, objects}) do
    {:ok, unwrap_query(objects)}
  end
  def unwrap_query(objects) do
    List.first objects
  end

  def unlabel_query({:ok, labeled_data}) do
    {:ok, unlabel_query(labeled_data)}
  end
  def unlabel_query(labeled_data) do
    label = labeled_data |> Map.keys |> List.first
    Map.get(labeled_data, label)
  end

  def atomize_query({:ok, string_map}) do
    atom_map = for {key, val} <- string_map, into: %{}, do: {String.to_atom(key), val}
    {:ok, atom_map}
  end

  @doc """
  Clears the database. This should only be used in a testing environment.
  """
  def clear() do
    query = clear_cypher()
    Neo4j.query(Neo4j.conn, query)
  end

  defp find_thought_list_cypher(limit, skip) do
    """
      MATCH (#{@t}:Thought)
      RETURN #{@t}
      SKIP #{skip}
      LIMIT #{limit}
    """
  end

  defp append_group_label_cypher(id) do
    """
      MATCH (#{@t}:Thought {_id: \"#{id}\"})
      SET #{@t} :Group
      return #{@t}
    """
  end

  defp find_related_cypher(id) do
    """
      MATCH (parent:Group {_id: \"#{id}\"})
      WITH parent
      MATCH (parent)<-[:NOTE_ON]-(#{@n}:Note),
        (#{@t})<-[:GROUP_ON]-(#{@g}:Group)
      RETURN collect(#{@n}), collect(#{@g})
    """
  end

  defp find_related_groups_cypher(id) do
    """
      MATCH (parent:Group {_id: \"#{id}\"})
      WITH parent
      MATCH (parent)<-[:GROUP_ON]-(#{@g}:Group)
      RETURN collect(#{@g})
    """
  end

  defp find_related_notes_cypher(id) do
    """
      MATCH (parent:Group {_id: \"#{id}\"})
      WITH parent
      MATCH (parent)<-[:NOTE_ON]-(#{@n}:Note)
      RETURN collect(#{@n})
    """
  end

  defp find_parent_cypher(id) do
    """
      MATCH (self:Group {_id: \"#{id}\"})
      WITH self
      MATCH (self)-[:GROUP_ON]->(parent:Group)
      RETURN parent
    """
  end

  defp clear_cypher() do
    """
      MATCH (n)
      DETACH DELETE n
    """
  end
end
