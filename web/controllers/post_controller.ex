defmodule Thoughtshare.PostController do
  use Thoughtshare.Web, :controller
  alias Thoughtshare.AuthController
  alias Thoughtshare.Cyphers
  alias Neo4j.Sips, as: Neo4j

  plug Guardian.Plug.EnsureAuthenticated,
    %{ on_failure: { AuthController, :unauthenticated_api }}
    when not action in [:index, :show, :index_reply]

  def index(conn, req) do
    fetch_posts_cypher = """
      MATCH (post:POST)
      MATCH (post)<-[:CREATED]-(rawUser:USER)
      RETURN post, {username: rawUser.username, id: rawUser.id} as user
    """
    {:ok, fetch_posts_res} = Neo4j.query(Neo4j.conn, fetch_posts_cypher)

    json conn |> put_status(200), %{"data" => fetch_posts_res}
  end

  def show(conn, req) do
    %{"id" => post_id} = req
    fetch_post_by_id_cypher = """
      MATCH (post:POST)
      WHERE post.id = \"#{post_id}\"
      MATCH (post)<-[:CREATED]-(rawUser:USER)
      RETURN post, {username: rawUser.username, id: rawUser.id} as user;
    """
    {:ok, fetch_res} = Neo4j.query(Neo4j.conn, fetch_post_by_id_cypher)

    json conn |> put_status(200), %{"data" => fetch_res}
  end

  def create(conn, req) do
    %{"title" => title, "link" => link, "desc" => desc} = req
    %{"id" => user_id} = Guardian.Plug.current_resource(conn)
    post_id = UUID.uuid1()
    created_at = :os.system_time(:seconds)
    create_post_cypher = """
      MATCH (user:USER)
      WHERE user.id = \"#{user_id}\"
      CREATE (user)-[:CREATED]->(post:POST {title: \"#{title}\",
        desc: \"#{desc}\", link: \"#{link}\", ups: "0", downs: "0",
        id: \"#{post_id}\", createdAt: \"#{created_at}\"})
      RETURN post;
    """
    {:ok, create_post_res} = Neo4j.query(Neo4j.conn, create_post_cypher)

    json conn |> put_status(201), %{"data" => create_post_res}
  end

  def index_reply(conn, req) do
    %{"id" => post_id} = req
    fetch_replies_cypher = """
      MATCH (post:POST)
      WHERE post.id = \"#{post_id}\"
      MATCH (post)<-[:REPLY_TO]-(reply:REPLY)
      MATCH (reply)<-[:CREATED]-(rawUser:USER)
      RETURN reply, {username: rawUser.username, id: rawUser.id} as user;
    """
    {:ok, fetch_replies_res} = Neo4j.query(Neo4j.conn, fetch_replies_cypher)

    json conn |> put_status(200), %{"data" => fetch_replies_res}
  end

  def create_reply(conn, req) do
    %{"title" => title, "link" => link, "desc" => desc, "id" => parent_id} = req
    %{"id" => user_id} = Guardian.Plug.current_resource(conn)
    reply_id = UUID.uuid1()
    created_at = :os.system_time(:seconds)

    create_reply_cypher = """
      MATCH (user:USER)
      WHERE user.id = \"#{user_id}\"
      MATCH (parent:POST)
      WHERE parent.id = \"#{parent_id}\"
      CREATE (user)-[:CREATED]->(reply:REPLY {title: \"#{title}\",
        link: \"#{link}\", desc: \"#{desc}\", ups: "0", downs: "0",
        id: \"#{reply_id}\", createdAt: \"#{created_at}\"})-[:REPLY_TO]->(parent)
      RETURN reply;
    """
    {:ok, create_reply_res} = Neo4j.query(Neo4j.conn, create_reply_cypher)

    json conn |> put_status(201), %{"data" => create_reply_res}
  end
end
