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
  end

  scope "/", Thoughtshare do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
  end

  # Other scopes may use custom stacks.
  scope "/api", Thoughtshare do
    pipe_through :api

    post "/posts", PostController, :create
  end
end
