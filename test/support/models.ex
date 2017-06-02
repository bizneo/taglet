defmodule TagletPost do
  use Ecto.Schema

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

