defmodule Thoughtshare.Router do
  use Thoughtshare.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug Plug.Parsers, parsers: [:json],
                       pass: ["application/json"],
                       json_decoder: Poison
    plug Guardian.Plug.VerifyHeader
    plug Guardian.Plug.LoadResource
  end

  scope "/", Thoughtshare do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
  end

  scope "/api", Thoughtshare do
    pipe_through :api

    post "/login", AuthController, :login
    post "/logout", AuthController, :logout
    get "/me", AuthController, :me

    post "/users", UserController, :create

    get "/users/:id", UserController, :show

    get "/posts", PostController, :index
    post "/posts", PostController, :create

    get "/posts/:id", PostController, :show

    get "/posts/:id/replies", PostController, :index_reply
    post "/posts/:id/replies", PostController, :create_reply

    # post "/posts/:id/topics", PostController, :create_topic
  end

  scope "/api/v2", Thoughtshare do
    pipe_through :api

    post "/login", AuthController, :login
    post "/logout", AuthController, :logout

    get "/users", UserController, :index
    post "/users", UserController, :create
    get "/users/:id", UserController, :show
    put "/users/:id", UserController, :update

    get "/thoughts", ThoughtController, :index
    post "/thoughts", ThoughtController, :create
    get "/thoughts/:id", ThoughtController, :show
    put "/thoughts/:id", ThoughtController, :update

    # get "/thoughts/:id/groups", GroupController, :index
    # post "/thoughts/:id/groups", GroupController, :create
    get "/groups/:id/groups", GroupController, :index
    post "/groups/:id/groups", GroupController, :create
    get "/groups/:id", GroupController, :show
    put "/groups/:id", GroupController, :update

    # get "/thoughts/:id/notes", NoteController, :index
    # post "/thoughts/:id/notes", NoteController, :create
    get "/groups/:id/notes", NoteController, :index
    post "/groups/:id/notes", NoteController, :create
    get "/notes/:id", NoteController, :show
    put "/notes/:id", NoteController, :update
  end
end
