defmodule Taglet.TagletQuery do
  import Ecto.{Query}
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
    |> order_by([m, t, tg], asc: m.inserted_at)
    |> select([m, tg, t], m)
  end

  @doc """
  Build the query to get all Tags of a tag_resource and context.
  """
  def get_tags_association(struct, tag_resource, context)  do
    taggable_type = struct.__struct__
    |> Module.split
    |> List.last

    case struct.id do
      nil -> get_all_tags(tag_resource, taggable_type, context)
      _ -> get_only_tags_related(tag_resource, taggable_type, struct.id, context)
    end
  end

  # Get ALL Tags related to context and taggable_type
  defp get_all_tags(tag_resource, taggable_type, context) do
    Tagging
    |> where([t],
      t.tag_id == ^tag_resource.id
      and t.taggable_type == ^taggable_type
      and t.context == ^context
    )
  end

  # Get only the tags related to a taggable_id
  defp get_only_tags_related(tag_resource, taggable_type, taggable_id, context) do
    tag_resource
    |> get_all_tags(taggable_type, context)
    |> where([t], t.taggable_id == ^taggable_id)
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
