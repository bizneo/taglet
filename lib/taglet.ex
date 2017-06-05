defmodule Taglet do
  @moduledoc """
  Documentation for Taglet.
  """
  import Ecto.Query
  alias Taglet.{Tagging, Tag}

  @repo Taglet.RepoClient.repo

  @doc """
  """
  def add(struct, tag, context \\ "tag") do
    tag_list = tag_list(struct, context)

    case tag in tag_list do
      true  -> tag_list
      false ->
        tag_resource = get_or_create(tag)

        @repo.insert!(%Tagging{
          taggable_id: struct.id,
          taggable_type: struct.__struct__ |> Module.split |> List.last,
          context: context,
          tag_id: tag_resource.id
        })

        List.insert_at(tag_list, -1, tag)
    end
  end

  defp get_or_create(tag) do
    case @repo.get_by(Tag, name: tag) do
      nil -> @repo.insert!(%Tag{name: tag})
      tag_resource -> tag_resource
    end
  end

  def tag_list(struct, context \\ "tag") do
    id = struct.id
    type = struct.__struct__ |> Module.split |> List.last

    Tag
    |> join(:inner, [t], tg in Tagging, t.id == tg.tag_id)
    |> where([t, tg],
      tg.context == ^context
      and
      tg.taggable_id == ^id
    )
    |> order_by([t, tg], asc: tg.inserted_at)
    |> @repo.all
    |> Enum.map(fn(result) -> result.name end)
  end
end
