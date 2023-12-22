defmodule AppWeb.PostLive.Index do
  use AppWeb, :live_view

  alias App.Communication
  alias App.Communication.Post

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: App.CommunicationBroadcaster.subscribe()
    {:ok, stream(socket, :posts, Communication.list_posts(), at: 0, limit: 10)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Post")
    |> assign(:post, %Post{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Posts")
    |> assign(:post, nil)
  end

  @impl true
  def handle_info({AppWeb.PostLive.FormComponent, {:saved, post}}, socket) do
    App.CommunicationBroadcaster.broadcast({:saved, post})
    {:noreply, stream_insert(socket, :posts, post, at: 0)}
  end

  @impl true
  def handle_info({:saved, post}, socket) do
    {:noreply, stream_insert(socket, :posts, post, at: 0)}
  end

  @impl true
  def handle_event("refresh", _value, socket) do
    {:noreply, push_navigate(socket, to: ~p"/posts")}
  end
end
