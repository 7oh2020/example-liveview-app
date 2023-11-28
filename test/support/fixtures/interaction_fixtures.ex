defmodule App.InteractionFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `App.Interaction` context.
  """

  @doc """
  Generate a like.
  """
  def like_fixture(%{user: user, post: post}) do
    {:ok, like} = App.Interaction.create_like(user, post)

    like
  end
end
