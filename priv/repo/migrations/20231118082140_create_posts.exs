defmodule App.Repo.Migrations.CreatePosts do
  use Ecto.Migration

  def change do
    create table(:posts) do
      add :body, :string, null: false
      add :like_count, :integer, default: 0, null: false
      add :path, :string
      add :user_id, references(:users, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:posts, [:user_id])
  end
end
