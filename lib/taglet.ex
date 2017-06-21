defmodule Taglet do
  import Ecto.{Query, Queryable}
  alias Taglet.{Tagging, Tag}

  @moduledoc """
  Documentation for Taglet.
  """

  @repo Taglet.RepoClient.repo

  @type tags                :: String.t | list
  @type tag                 :: String.t
  @type context             :: String.t
  @type tag_list            :: list
  @type persisted_struct    :: struct

  @doc """
  Get a persisted struct and inserts a new tag associated to this
  struct for a specific context.

  You can pass a tag or a list of tags.

  In case the tag is duplicated nothing will happen.

  It returns a list of associated tags
  """
  @spec add(struct, tags, context) :: struct
  def add(struct, tags, context \\ "tags")
  def add(struct, tag, context) when is_bitstring(tag), do: add(struct, [tag], context)
  def add(struct, tags, context) do
    tag_list = tag_list(struct, context)
    new_tags = tags -- tag_list

    case new_tags do
      [] ->
        put_tags(struct, context, tag_list)
      new_tags ->
        taggings = Enum.map(new_tags, fn(tag) ->
          generate_tagging(struct, tag, context)
        end)

        @repo.insert_all(Tagging, taggings)

        put_tags(struct, context, tag_list ++ new_tags)
    end
  end

  defp generate_tagging(struct, tag, context) do
    tag_resource = get_or_create(tag)

    %{
      taggable_id: struct.id,
      taggable_type: struct.__struct__ |> taggable_type,
      context: context,
      tag_id: tag_resource.id,
      inserted_at: Ecto.DateTime.utc
    }
  end

  @doc """
  Get a persisted struct and removes the tag association for
  a specific context.

  In case the association doesn't exist nothing will happen.

  It returns a list of associated tags
  """
  @spec remove(struct, tag, context) :: tag_list
  def remove(struct, tag, context \\ "tags") do
    tag_list = tag_list(struct, context)

    case tag in tag_list do
      true ->
        struct
        |> get_association(get_or_create(tag), context)
        |> @repo.delete!

        put_tags(struct, context, List.delete(tag_list, tag))
      false ->
        put_tags(struct, context, tag_list)
    end
  end

  defp get_or_create(tag) do
    case @repo.get_by(Tag, name: tag) do
      nil -> @repo.insert!(%Tag{name: tag})
      tag_resource -> tag_resource
    end
  end

  defp get_association(struct, tag_resource, context) do
    @repo.get_by(Tagging,
    taggable_id: struct.id,
    taggable_type: struct.__struct__ |> taggable_type,
    context: context,
    tag_id: tag_resource.id
    )
  end

  defp put_tags(struct, context, tags) do
    Map.put(struct, String.to_atom(context), tags)
  end

  @doc """
  Given a struct, it searchs the associated tags for a specific
  context.

  It returns a list of associated tags ordered by `insert_date`
  """
  @spec tag_list(struct, context) :: tag_list
  def tag_list(struct, context \\ "tags") do
    id = struct.id
    type = struct.__struct__ |> taggable_type

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

  @doc """
  Search for all tags associated to a taggable_type
  and a context
  """
  @spec tags(module, context) :: list
  def tags(model, context \\ "tags") do
    type = taggable_type(model)

    Tag
    |> join(:inner, [t], tg in Tagging, t.id == tg.tag_id)
    |> where([t, tg],
      tg.context == ^context
      and
      tg.taggable_type == ^type
    )
    |> distinct([t, tg], t.name)
    |> order_by([t, tg], asc: tg.inserted_at)
    |> @repo.all
    |> Enum.map(fn(result) -> result.name end)
  end

  @doc """
  Given a tag, model and context ('tag' by default), will find
  all the model resources associated to the given tag.
  """
  @spec tagged_with(tags, module, context) :: list
  def tagged_with(tags, model, context \\ "tags") do
    do_tags_search(model, tags, context) |> @repo.all
  end

  def tagged_with_query(query, tags, context \\ "tags") do
    do_tags_search(query, tags, context)
  end

  defp do_tags_search(queryable, tags, context) do
    %{from: {_source, schema}} = Ecto.Queryable.to_query(queryable)
    type = taggable_type(schema)
    tags_size = length(tags)

    queryable
    |> join(:inner, [m], tg in Tagging,
      tg.taggable_type == ^type
      and
      tg.context == ^context
      and
      m.id == tg.taggable_id
    )
    |> join(:inner, [m, tg], t in Tag, t.id == tg.tag_id)
    |> where([m, tg, t], t.name in ^tags)
    |> group_by([m, tg, t], m.id)
    |> having([m, tg, t], count(tg.taggable_id) == ^tags_size)
    |> select([m, tg, t], m)
  end

  defp taggable_type(module), do: module |> Module.split |> List.last
end
