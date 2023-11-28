defmodule App.Interaction.Like do
  use Ecto.Schema
  import Ecto.Changeset

  schema "likes" do
    belongs_to(:user, App.Accounts.User)
    belongs_to(:post, App.Communication.Post)

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(like, attrs) do
    like
    |> cast(attrs, [:user_id, :post_id])
    |> validate_required([:user_id, :post_id])
  end
end
