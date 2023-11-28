defmodule AppWeb.PostLiveTest do
  use AppWeb.ConnCase

  import Phoenix.LiveViewTest
  import App.CommunicationFixtures

  setup :register_and_log_in_user

  @create_attrs %{body: "some body"}
  @update_attrs %{body: "some updated body"}
  @invalid_attrs %{body: nil}

  describe "Index" do
    test "lists all posts", %{conn: conn, user: user} do
      post = post_fixture(%{user: user})
      {:ok, _index_live, html} = live(conn, ~p"/posts")

      assert html =~ "Listing Posts"
      assert html =~ post.body
    end

    test "saves new post", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/posts")

      assert index_live |> element("a", "New Post") |> render_click() =~
               "New Post"

      assert_patch(index_live, ~p"/posts/new")

      assert index_live
             |> form("#post-form", post: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert index_live
             |> form("#post-form", post: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/posts")

      html = render(index_live)
      assert html =~ "Post created successfully"
      assert html =~ "some body"
    end
  end

  describe "Show" do
    test "displays post", %{conn: conn, user: user} do
      post = post_fixture(%{user: user})
      {:ok, _show_live, html} = live(conn, ~p"/posts/#{post}")

      assert html =~ "Show Post"
      assert html =~ post.body
    end

    test "updates post within modal", %{conn: conn, user: user} do
      post = post_fixture(%{user: user})
      {:ok, show_live, _html} = live(conn, ~p"/posts/#{post}")

      assert show_live |> element("a", "Edit") |> render_click() =~
               "Edit Post"

      assert_patch(show_live, ~p"/posts/#{post}/show/edit")

      assert show_live
             |> form("#post-form", post: @invalid_attrs)
             |> render_change() =~ "can&#39;t be blank"

      assert show_live
             |> form("#post-form", post: @update_attrs)
             |> render_submit()

      assert_patch(show_live, ~p"/posts/#{post}")

      html = render(show_live)
      assert html =~ "Post updated successfully"
      assert html =~ "some updated body"
    end

    test "deletes post in listing", %{conn: conn, user: user} do
      post = post_fixture(%{user: user})
      {:ok, show_live, html} = live(conn, ~p"/posts/#{post}")

      assert html =~ "Delete"
      assert show_live |> element("a", "Delete") |> render_click()

      assert_redirect(show_live, ~p"/posts")
    end

    test "いいねボタンを押すといいね数が更新されること", %{conn: conn, user: user} do
      post = post_fixture(%{user: user})
      {:ok, show_live, _html} = live(conn, ~p"/posts/#{post}")

      assert show_live |> element("button", "0 Likes") |> render_click() =~ "1 Likes"

      assert show_live |> element("button", "1 Likes") |> render_click() =~ "0 Likes"
    end
  end

  describe "show other posts" do
    import App.AccountsFixtures

    setup do
      user = user_fixture()
      post = post_fixture(%{user: user})
      %{post: post}
    end

    test "他人のPostは編集できないこと", %{conn: conn, post: post} do
      {:ok, _show_live, html} = live(conn, ~p"/posts/#{post}")
      refute html =~ "Edit"
    end

    test "他人のPostは削除できないこと", %{conn: conn, post: post} do
      {:ok, _show_live, html} = live(conn, ~p"/posts/#{post}")
      refute html =~ "Delete"
    end
  end

  describe "upload" do
    test "Postにアップロード画像を添付できること", %{conn: conn} do
      {:ok, index_live, _html} = live(conn, ~p"/posts")

      assert index_live |> element("a", "New Post") |> render_click() =~
               "New Post"

      assert_patch(index_live, ~p"/posts/new")

      assert index_live
             |> file_input("#post-form", :images, [
               %{
                 name: "hello.png",
                 type: "image/png",
                 content: File.read!("test/support/uploads/hello.png")
               }
             ])
             |> render_upload("hello.png") =~ "hello.png"

      assert index_live
             |> form("#post-form", post: @create_attrs)
             |> render_submit()

      assert_patch(index_live, ~p"/posts")

      html = render(index_live)
      assert html =~ "Post created successfully"
      assert html =~ "some body"
    end
  end
end
