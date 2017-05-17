defmodule Mix.Tasks.Taglet.Install do
  @shortdoc "generates taglet migration file for the database"

  use Mix.Task

  import Macro, only: [underscore: 1]
  import Mix.Generator

  def run(_args) do
    path = Path.relative_to("priv/repo/migrations", Mix.Project.app_path)
    tag_file = Path.join(path, "#{timestamp()}_create_tag.exs")
    tagging_file = Path.join(path, "#{timestamp()}_create_tagging.exs")
    create_directory path

    create_file tag_file, """
    defmodule Repo.Migrations.CreateTag do
      use Ecto.Migration

      def change do
        create table(:tags) do
          add :name, :string, null: false
        end
      end
    end
    """


    create_file tagging_file, """
    defmodule Repo.Migrations.CreateTagging do
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
    """
  end

  defp timestamp, do: :os.system_time(:seconds)
end
