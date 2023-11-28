defmodule App.Interaction do
  @moduledoc """
  The Interaction context.
  """

  import Ecto.Query, warn: false
  alias App.Repo
  alias App.Accounts.User
  alias App.Communication.Post
  alias App.Interaction.Like

  @doc """
  post_idにマッチするPostのリストを返します。
  """
  def list_likes_by_post_id(post_id) do
    query =
      from(
        l in Like,
        where: l.post_id == ^post_id,
        join: u in assoc(l, :user),
        preload: [user: u],
        order_by: [desc: l.inserted_at],
        limit: 10
      )

    Repo.all(query)
  end

  @doc """
  IDにマッチするLikeを1つ返します。
  """
  def get_like(user_id, post_id) do
    query =
      from(
        l in Like,
        where: l.post_id == ^post_id and l.user_id == ^user_id
      )

    Repo.one(query)
  end

  @doc """
  Likeが存在する場合は削除、なければ作成します。
  """
  def toggle_like(%User{} = user, %Post{} = post) do
    # いいねデータが存在する場合は削除、なければ作成する
    if like_exists?(user.id, post.id) do
      like = get_like(user.id, post.id)

      case delete_like(like) do
        {:ok, %Like{} = like} -> {:ok, :delete, like}
        {:error, %Ecto.Changeset{} = changeset} -> {:error, :delete, changeset}
      end
    else
      case create_like(user, post) do
        {:ok, %Like{} = like} -> {:ok, :create, like}
        {:error, %Ecto.Changeset{} = changeset} -> {:error, :create, changeset}
      end
    end
  end

  @doc """
  Likeが存在するかbooleanで返します。
  """
  def like_exists?(user_id, post_id) do
    Repo.exists?(
      from(
        l in Like,
        where: l.user_id == ^user_id and l.post_id == ^post_id,
        select: {l.id}
      )
    )
  end

  @doc """
  Likeを作成します。
  """
  def create_like(%User{} = user, %Post{} = post) do
    Ecto.Multi.new()
    |> Ecto.Multi.one(
      :post,
      from(p in Post, where: p.id == ^post.id)
    )
    |> Ecto.Multi.update(:set_count, fn %{post: post} ->
      Post.like_count_changeset(post, %{like_count: post.like_count + 1})
    end)
    |> Ecto.Multi.insert(
      :create_like,
      registration_change_like(%Like{}, user, post)
    )
    |> Repo.transaction()
    |> case do
      {:ok, %{create_like: like}} ->
        {:ok, like}

      {:error, _name, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Likeを削除します。
  """
  def delete_like(%Like{} = like) do
    Ecto.Multi.new()
    |> Ecto.Multi.one(
      :post,
      from(p in Post, where: p.id == ^like.post_id)
    )
    |> Ecto.Multi.update(:set_count, fn %{post: post} ->
      Post.like_count_changeset(post, %{like_count: post.like_count - 1})
    end)
    |> Ecto.Multi.delete(:delete_like, like)
    |> Repo.transaction()
    |> case do
      {:ok, %{delete_like: like}} ->
        {:ok, like}

      {:error, _name, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Likeの作成のための`%Ecto.Changeset{}`を返します。
  """
  def registration_change_like(%Like{} = like, user, post) do
    like
    |> Repo.preload([:user, :post])
    |> Like.changeset(%{user_id: user.id, post_id: post.id})
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Ecto.Changeset.put_assoc(:post, post)
  end
end
