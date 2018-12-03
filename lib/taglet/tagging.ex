defmodule Taglet.Tagging do
  use Ecto.Schema
  import Ecto.Changeset

  @taggable_id_type if Application.get_env(:taglet, :taggable_id) == :uuid, do: :id, else: :integer

  schema "taggings" do
    field :taggable_id, @taggable_id_type, null: false
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
