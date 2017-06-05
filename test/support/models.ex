defmodule TagletPost do
  use Ecto.Schema
  use Taglet.ModelManager, :tags
  use Taglet.ModelManager, :categories

  import Ecto.Changeset
  import Ecto.Query

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

