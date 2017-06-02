defmodule Taglet.Repo.Migrations.CreatePost do
  use Ecto.Migration

  def change do
    create table(:posts) do
      add :title, :string, null: false
      add :body,  :string

      timestamps()
    end
  end
end
