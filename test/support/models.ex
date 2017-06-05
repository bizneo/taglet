defmodule TagletPost do
  use Ecto.Schema
  use Taglet.TagAs, :tags
  use Taglet.TagAs, :categories

  import Ecto.Changeset

  schema "posts" do
    field :title, :string
    field :body, :boolean

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:title, :body])
    |> validate_required([:title])
  end
end

