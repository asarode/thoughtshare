defmodule Thoughtshare.PostController do
  use Thoughtshare.Web, :controller
  alias Thoughtshare.Cyphers
  alias Neo4j.Sips, as: Neo4j

  def index(conn, res) do
    fetch_node_by_id_cypher = Cyphers.fetch_node_by_id(res)
    {:ok, fetch_res} = Neo4j.tx_commit(Neo4j.conn, fetch_node_by_id_cypher)

    json conn |> put_status(200), %{"data" => fetch_res}
  end

  def create(conn, res) do

    # Query the database for a node with the same information as the child
    check_child_cypher = Cyphers.check_child(res)
    {:ok, check_child_res} = Neo4j.query(Neo4j.conn, check_child_cypher)

    if length(check_child_res) == 0 do

      # Create the child if it didn't already exist
      create_child_cypher = Cyphers.create_child(res)
      {:ok, create_child_res} = Neo4j.tx_commit(Neo4j.conn, create_child_cypher)

      json conn |> put_status(201), %{"data" => create_child_res}
    else
      json conn |> put_status(200), %{"data" => "Node already exists"}
    end
  end
end
