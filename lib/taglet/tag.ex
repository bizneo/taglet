defmodule Taglet.Tag do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  schema "tags" do
    field :name, :string, null: false

    has_many :taggings, Taglet.Tagging
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:name])
    |> validate_required(:name)
  end
end
