defmodule AppWeb.PostLive.Show do
  use AppWeb, :live_view

  alias App.Communication
  alias App.Interaction
  alias App.Interaction.Like

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    post = Communication.get_post!(id)
    user = socket.assigns.current_user

    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:can_update, Communication.can?(user, :update, post))
     |> assign(:can_delete, Communication.can?(user, :delete, post))
     |> assign(:post, post)
     |> assign(:like_count, post.like_count)
     |> stream(:likes, Interaction.list_likes_by_post_id(post.id), at: 0, limit: 10)}
  end

  defp page_title(:show), do: "Show Post"
  defp page_title(:edit), do: "Edit Post"

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    post = Communication.get_post!(id)
    user = socket.assigns.current_user

    case Communication.delete_post(user, post) do
      {:ok, _} ->
        delete_file!(post.path)
        {:noreply, push_navigate(socket, to: ~p"/posts", replace: true)}

      {:error, "permission denied"} ->
        raise AppWeb.PermissionError
    end
  end

  @impl true
  def handle_event("like", %{"id" => id}, socket) do
    post = Communication.get_post!(id)
    user = socket.assigns.current_user

    case Interaction.toggle_like(user, post) do
      {:ok, :create, %Like{} = like} ->
        {:noreply,
         socket
         |> update(:like_count, &(&1 + 1))
         |> stream_insert(:likes, like)}

      {:ok, :delete, %Like{} = like} ->
        {:noreply,
         socket
         |> update(:like_count, &(&1 - 1))
         |> stream_delete(:likes, like)}

      {:error, :create, %Ecto.Changeset{}} ->
        {:noreply, put_flash(socket, :error, "いいねの途中でエラーが発生しました")}

      {:error, :delete, %Ecto.Changeset{}} ->
        {:noreply, put_flash(socket, :error, "いいねの取り消しの途中でエラーが発生しました")}
    end
  end

  defp delete_file!(post_path) do
    if !is_nil(post_path) do
      path = Path.join([:code.priv_dir(:app), "static", post_path])
      File.rm!(path)
    end
  end
end
