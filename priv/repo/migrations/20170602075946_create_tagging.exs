defmodule Taglet.Repo.Migrations.CreateTagging do
  use Ecto.Migration

  def change do
    create table(:taggings) do
      add :tag_id, references(:tags, on_delete: :delete_all)

      add :taggable_id,      :integer
      add :taggable_type,    :string, null: false

      add :context, :string, null: false, default: "tag"

      add :inserted_at,  :utc_datetime, null: false
    end

    create index(:taggings, [:tag_id])
    create index(:taggings, [:taggable_id, :taggable_type, :context])
  end
end
