defmodule App.CommunicationTest do
  use App.DataCase

  alias App.Communication

  describe "posts" do
    alias App.Communication.Post

    import App.CommunicationFixtures
    import App.AccountsFixtures

    @invalid_attrs %{body: nil}

    test "list_posts/0 returns all posts" do
      user = user_fixture()
      post = post_fixture(%{user: user})
      assert Communication.list_posts() == [Map.put(post, :user, user)]
    end

    test "get_post!/1 returns the post with given id" do
      user = user_fixture()
      post = post_fixture(%{user: user})
      assert Communication.get_post!(post.id) == Map.put(post, :user, user)
    end

    test "create_post/1 with valid data creates a post" do
      user = user_fixture()
      valid_attrs = %{body: "some body"}

      assert {:ok, %Post{} = post} = Communication.create_post(user, valid_attrs)
      assert post.body == "some body"
      assert post.user_id == user.id
    end

    test "create_post/1 with invalid data returns error changeset" do
      user = user_fixture()
      assert {:error, %Ecto.Changeset{}} = Communication.create_post(user, @invalid_attrs)
    end

    test "update_post/2 with valid data updates the post" do
      user = user_fixture()
      post = post_fixture(%{user: user})
      update_attrs = %{body: "some updated body"}

      assert {:ok, %Post{} = post} = Communication.update_post(user, post, update_attrs)
      assert post.body == "some updated body"
    end

    test "update_post/2 with invalid data returns error changeset" do
      user = user_fixture()
      post = post_fixture(%{user: user})
      assert {:error, %Ecto.Changeset{}} = Communication.update_post(user, post, @invalid_attrs)
      assert post == Communication.get_post!(post.id)
    end

    test "delete_post/1 deletes the post" do
      user = user_fixture()
      post = post_fixture(%{user: user})
      assert {:ok, %Post{}} = Communication.delete_post(user, post)
      assert_raise Ecto.NoResultsError, fn -> Communication.get_post!(post.id) end
    end

    test "change_post/1 returns a post changeset" do
      user = user_fixture()
      post = post_fixture(%{user: user})
      assert %Ecto.Changeset{} = Communication.change_post(post)
    end

    test "registration_change_post/2 returns a post changeset" do
      user = user_fixture()
      post = post_fixture(%{user: user})
      assert %Ecto.Changeset{} = Communication.registration_change_post(post, user.id)
    end
  end

  describe "other posts" do
    import App.CommunicationFixtures
    import App.AccountsFixtures

    setup do
      user = user_fixture()
      post = post_fixture(%{user: user})

      %{post: post}
    end

    test "update_post/3 他人のPostは更新できないこと", %{post: post} do
      user = user_fixture()
      update_attrs = %{body: "some updated body"}

      assert {:error, "permission denied"} = Communication.update_post(user, post, update_attrs)
    end

    test "delete_post/2 他人のPostは削除できないこと", %{post: post} do
      user = user_fixture()

      {:error, "permission denied"} = Communication.delete_post(user, post)
    end
  end

  describe "posts authorization" do
    import App.CommunicationFixtures
    import App.AccountsFixtures

    test "Postに対する権限が取得できること" do
      u1 = user_fixture()
      p1 = post_fixture(%{user: u1})
      u2 = user_fixture()
      p2 = post_fixture(%{user: u2})

      assert Communication.can?(u1, :update, p1)
      assert Communication.can?(u1, :delete, p1)
      refute Communication.can?(u1, :update, p2)
      refute Communication.can?(u1, :delete, p2)
    end
  end
end
