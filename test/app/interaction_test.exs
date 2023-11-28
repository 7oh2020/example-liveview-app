defmodule App.InteractionTest do
  use App.DataCase

  alias App.Interaction

  describe "likes" do
    alias App.Interaction.Like
    alias App.Communication
    alias App.Communication.Post

    import App.AccountsFixtures
    import App.CommunicationFixtures
    import App.InteractionFixtures

    test "toggle_like/2 Likeが存在する場合は削除、なければ作成できること" do
      user = user_fixture()
      post = post_fixture(%{user: user})
      like_fixture(%{user: user, post: post})
      assert Interaction.like_exists?(user.id, post.id)
      assert {:ok, :delete, _} = Interaction.toggle_like(user, post)
      refute Interaction.like_exists?(user.id, post.id)
      assert {:ok, :create, _} = Interaction.toggle_like(user, post)
      assert Interaction.like_exists?(user.id, post.id)
    end

    test "list_likes_by_post_id/1 post_idにマッチするLikeが取得できること" do
      user = user_fixture()
      post = post_fixture(%{user: user})
      like = like_fixture(%{user: user, post: post})

      assert [result | _] =
               Interaction.list_likes_by_post_id(post.id)

      assert result.user_id == like.user_id
      assert result.post_id == like.post_id
    end

    test "get_like/2 Likeが取得できること" do
      user = user_fixture()
      post = post_fixture(%{user: user})
      like = like_fixture(%{user: user, post: post})

      refute Interaction.get_like(0, 0)

      assert result =
               Interaction.get_like(user.id, post.id)

      assert result.user_id == like.user_id
      assert result.post_id == like.post_id
    end

    test "like_exists?/2 Likeが存在するかbooleanで返されること" do
      user = user_fixture()
      post = post_fixture(%{user: user})
      like_fixture(%{user: user, post: post})
      assert Interaction.like_exists?(user.id, post.id)
      refute Interaction.like_exists?(0, 0)
    end

    test "create_like/2 正しいデータでLikeが作成できること" do
      user = user_fixture()
      post = post_fixture(%{user: user})

      assert {:ok, %Like{} = like} =
               Interaction.create_like(user, post)

      assert like.user_id == user.id
      assert like.post_id == post.id
      assert Interaction.like_exists?(user.id, post.id)
      assert %Post{like_count: 1} = Communication.get_post!(post.id)
    end

    test "delete_like/1 Likeが削除できること" do
      user = user_fixture()
      post = post_fixture(%{user: user})
      like = like_fixture(%{user: user, post: post})
      assert {:ok, %Like{}} = Interaction.delete_like(like)
      refute Interaction.like_exists?(user.id, post.id)
      assert %Post{like_count: 0} = Communication.get_post!(post.id)
    end

    test "registration_change_like/3 changesetが返されること" do
      user = user_fixture()
      post = post_fixture(%{user: user})
      like = like_fixture(%{user: user, post: post})

      assert %Ecto.Changeset{} =
               Interaction.registration_change_like(like, user, post)
    end
  end
end
