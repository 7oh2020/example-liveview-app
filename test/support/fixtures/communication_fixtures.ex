defmodule App.CommunicationFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `App.Communication` context.
  """

  @doc """
  Generate a post.
  """
  def post_fixture(attrs \\ %{}) do
    attrs =
      attrs
      |> Enum.into(%{
        body: "some body",
        like_count: 0
      })

    {:ok, post} =
      App.Communication.create_post(attrs[:user], attrs)

    post
  end
end
