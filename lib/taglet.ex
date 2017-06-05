defmodule Taglet do
  import Ecto.Query
  alias Taglet.{Tagging, Tag}

  @moduledoc """
  Documentation for Taglet.
  """

  @repo Taglet.RepoClient.repo

  @type tag                 :: bitstring
  @type context             :: bitstring
  @type tag_list            :: list
  @type persisted_struct    :: struct

  @doc """
  Get a persisted struct and inserts a new tag associated to this
  struct for a specific context.

  In case the tag is duplicated nothing will happen.

  It returns a list of associated tags
  """
  @spec add(struct, tag, context) :: tag_list
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

  @doc """
  Given a struct, it searchs the associated tags for a specific
  context.

  It returns a list of associated tags ordered by `insert_date`
  """
  @spec tag_list(struct, context) :: tag_list
  def tag_list(struct, context \\ "tag") do
    id = struct.id
    type = struct.__struct__ |> Module.split |> List.last

    Tag
    |> join(:inner, [t], tg in Tagging, t.id == tg.tag_id)
    |> where([t, tg],
      tg.context == ^context
      and
      tg.taggable_id == ^id
      and
      tg.taggable_type == ^type
    )
    |> order_by([t, tg], asc: tg.inserted_at)
    |> @repo.all
    |> Enum.map(fn(result) -> result.name end)
  end
end
