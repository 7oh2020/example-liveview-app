defmodule App.Communication do
  @moduledoc """
  The Communication context.
  """

  import Ecto.Query, warn: false
  alias App.Repo
  alias App.Accounts
  alias App.Accounts.User
  alias App.Communication.Post

  @doc """
  Postのリストを返します。
  """
  def list_posts do
    query =
      from(
        p in Post,
        join: u in assoc(p, :user),
        preload: [user: u],
        order_by: [desc: p.updated_at],
        limit: 10
      )

    Repo.all(query)
  end

  @doc """
  IDにマッチするPostを1つ返します。
  """
  def get_post!(id) do
    query =
      from(
        p in Post,
        where: p.id == ^id,
        join: u in assoc(p, :user),
        preload: [user: u]
      )

    Repo.one!(query)
  end

  @doc """
  Postを作成します。
  """
  def create_post(%User{id: user_id}, attrs \\ %{}) do
    %Post{}
    |> registration_change_post(user_id, attrs)
    |> Repo.insert()
  end

  @doc """
  Postを更新します。
  """
  def update_post(%User{} = user, %Post{} = post, attrs) do
    if can?(user, :update, post) do
      post
      |> Post.changeset(attrs)
      |> Repo.update()
    else
      {:error, "permission denied"}
    end
  end

  @doc """
  Postを削除します。
  """
  def delete_post(%User{} = user, %Post{} = post) do
    if can?(user, :delete, post) do
      Repo.delete(post)
    else
      {:error, "permission denied"}
    end
  end

  @doc """
  Postの更新のための`%Ecto.Changeset{}`を返します。
  """
  def change_post(%Post{} = post, attrs \\ %{}) do
    Post.changeset(post, attrs)
  end

  @doc """
  Postの作成のための`%Ecto.Changeset{}`を返します。
  """
  def registration_change_post(%Post{} = post, user_id, attrs \\ %{}) do
    user = Accounts.get_user!(user_id)

    post
    |> Repo.preload(:user)
    |> Post.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:user, user)
  end

  # Authorization

  @doc """
  リソースへの権限があるかbooleanで返します。

  - UserがPostの作成者の場合はtrueを返す。
  - UserがPostの作成者でない場合はfalseを返す。
  """
  def can?(%User{id: user_id}, action, %Post{user_id: user_id}) when action in [:update, :delete],
    do: true

  def can?(%User{}, action, %Post{}) when action in [:update, :delete],
    do: false
end
