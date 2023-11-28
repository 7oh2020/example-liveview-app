defmodule AppWeb.PostLive.FormComponent do
  use AppWeb, :live_component

  alias App.Communication

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>あなたの気持ちを世界に伝えましょう</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="post-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input
          field={@form[:body]}
          type="text"
          placeholder="今の気持ちは？"
          autocomplete="off"
        />
        <.live_file_input :if={@action == :new} upload={@uploads.images} />
        <%= for entry <- @uploads.images.entries do %>
          <figure>
            <.live_img_preview entry={entry} />
            <figcaption><%= entry.client_name %></figcaption>
          </figure>
          <progress value={entry.progress} max="100"><%= entry.progress %>%</progress>
          <%= for err <- upload_errors(@uploads.images, entry) do %>
            <p role="alert" class="alert alert-danger"><%= err %></p>
          <% end %>
        <% end %>
        <:actions>
          <.button phx-disable-with="Saving...">Save Post</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def mount(socket) do
    {:ok,
     allow_upload(socket, :images,
       accept: ~w(.jpg .jpeg .png),
       max_entries: 1,
       max_file_size: 4_000_000
     )}
  end

  @impl true
  def update(%{post: post} = assigns, socket) do
    changeset = Communication.change_post(post)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"post" => post_params}, socket) do
    changeset =
      socket.assigns.post
      |> Communication.change_post(post_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("save", %{"post" => post_params}, socket) do
    save_post(socket, socket.assigns.action, post_params)
  end

  defp save_post(socket, :edit, post_params) do
    user = socket.assigns.current_user

    case Communication.update_post(user, socket.assigns.post, post_params) do
      {:ok, post} ->
        notify_parent({:saved, post})

        {:noreply,
         socket
         |> put_flash(:info, "Post updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, "permission denied"} ->
        raise AppWeb.PermissionError

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_post(socket, :new, post_params) do
    {:ok, post_params} = save_file(socket, post_params)
    user = socket.assigns.current_user

    case Communication.create_post(user, post_params) do
      {:ok, post} ->
        notify_parent({:saved, post})

        {:noreply,
         socket
         |> put_flash(:info, "Post created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_file(socket, post_params) do
    image_files =
      consume_uploaded_entries(socket, :images, fn %{path: path}, entry ->
        # 実際はバイナリコードなどをチェックするべき
        ext = Path.extname(entry.client_name)
        dest = Path.join([:code.priv_dir(:app), "static", "uploads", Path.basename(path) <> ext])

        File.cp!(path, dest)
        {:ok, "/uploads/#{Path.basename(dest)}"}
      end)

    post_params =
      if length(image_files) > 0 do
        [file | _] = image_files
        Map.put(post_params, "path", file)
      else
        Map.put(post_params, "path", nil)
      end

    {:ok, post_params}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
