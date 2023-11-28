defmodule App.Communication.Post do
  use Ecto.Schema
  import Ecto.Changeset

  schema "posts" do
    field :body, :string
    field :like_count, :integer, default: 0
    field :path, :string
    belongs_to(:user, App.Accounts.User)
    many_to_many(:liked_users, App.Accounts.User, join_through: "likes")

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(post, attrs) do
    post
    |> cast(attrs, [:body, :like_count, :path])
    |> validate_required([:body])
    |> validate_length(:body, min: 1, max: 200)
  end

  @doc false
  def like_count_changeset(post, attrs) do
    post
    |> cast(attrs, [:like_count])
    |> validate_required([:like_count])
  end
end
