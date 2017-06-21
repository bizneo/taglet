defmodule Taglet.TagletQuery do
  import Ecto.{Query, Queryable}
  alias Taglet.{Tagging, Tag}

  @moduledoc """
  Allow to build essential ecto queries for taglet

  All this functions only should be used from Taglet module
  """

  @doc """
  Build the query to search tags in a specific context, struct or module
  """
  def search_tags(context, taggable_type, taggable_id \\ nil) do
    Tag
    |> join_taggings_from_tag(context, taggable_type, taggable_id)
    |> distinct([t, tg], t.name)
    |> order_by([t, tg], asc: tg.inserted_at)
    |> select([t, tg], t.name)
  end

  defp join_taggings_from_tag(query, context, taggable_type, nil) do
    query
    |> join(:inner, [t], tg in Tagging,
      t.id == tg.tag_id
      and
      tg.taggable_type == ^taggable_type
      and
      tg.context == ^context
    )
  end
  defp join_taggings_from_tag(query, context, taggable_type, taggable_id) do
    query
    |> join(:inner, [t], tg in Tagging,
      t.id == tg.tag_id
      and
      tg.taggable_type == ^taggable_type
      and
      tg.context == ^context
      and
      tg.taggable_id == ^taggable_id
    )
  end

  @doc """
  Build the query to search tagged resources
  """
  def search_tagged_with(query, tags, context, taggable_type) do
    tags_length = length(tags)

    query
    |> join_taggings_from_model(context, taggable_type)
    |> join_tags
    |> where([m, tg, t], t.name in ^tags)
    |> group_by([m, tg, t], m.id)
    |> having([m, tg, t], count(tg.taggable_id) == ^tags_length)
    |> select([m, tg, t], m)
  end

  defp join_taggings_from_model(query, context, taggable_type) do
    query
    |> join(:inner, [m], tg in Tagging,
      tg.taggable_type == ^taggable_type
      and
      tg.context == ^context
      and
      m.id == tg.taggable_id
    )
  end

  defp join_tags(query) do
    query
    |> join(:inner, [m, tg], t in Tag, t.id == tg.tag_id)
  end
end
