defmodule Thoughtshare.Cyphers do

  def fetch_post_by_id (info) do
    %{"id" => id} = info

    """
      MATCH (node:POST)
      WHERE node.id = \"#{id}\"
      RETURN node;
    """
  end

  def check_child (info) do
    %{"title" => title, "link" => link, "parent_id" => parent_id} = info

    """
      MATCH (child:POST)-[:RELATED_TO]->(parent:POST)
      WHERE child.title = \"#{title}\" AND child.link = \"#{link}\"
        AND parent.id = \"#{parent_id}\"
      RETURN child;
    """
  end

  def create_child (info) do
    %{"title" => title, "link" => link, "parent_id" => parent_id} = info

    child_id = UUID.uuid1()

    """
      MATCH (parent:POST)
      WITH parent
      WHERE parent.id = \"#{parent_id}\"
      CREATE path = (child:POST {title: \"#{title}\", link: \"#{link}\",
        ups: "1", downs: "0", id: \"#{child_id}\"})-[:RELATED_TO]->(parent)
      RETURN path;
    """
  end

  def fetch_user_by_id (info) do
    %{"id" => id} = info

    """
      MATCH (usr:USER)
      WHERE usr.id = \"#{id}\"
      RETURN usr;
    """
  end

  def create_user (info) do
    %{"email" => email, "password" => password} = info

  end
end
