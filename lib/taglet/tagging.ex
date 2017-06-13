defmodule Taglet.Tagging do
  use Ecto.Schema
  import Ecto.Changeset

  schema "taggings" do
    field :taggable_id, :integer, null: false
    field :taggable_type, :string, null: false
    field :context, :string, null: false

    timestamps(updated_at: false)

    belongs_to :tag, Taglet.Tag
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:taggable_id, :taggable_type, :context, :tag_id])
    |> validate_required([:taggable_id, :taggable_type, :context, :tag_id])
  end
end
