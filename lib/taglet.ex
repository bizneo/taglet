defmodule Taglet do
  alias Taglet.{Tagging, Tag, TagletQuery}

  @moduledoc """
  Documentation for Taglet.
  Taglet allows you to manage tags associated to your records.

  Please read README.md to get more info about how to use that
  package.
  """

  @repo Taglet.RepoClient.repo

  @type taggable            :: module | struct
  @type tags                :: String.t | list
  @type tag                 :: String.t
  @type context             :: String.t
  @type tag_list            :: list

  @doc """
  Get a persisted struct and inserts a new tag associated to this
  struct for a specific context.

  You can pass a tag or a list of tags.

  In case the tag would be duplicated nothing will happen.

  It returns the struct with a new entry for the given context.
  """
  @spec add(struct, tags, context) :: struct
  def add(struct, tags, context \\ "tags")
  def add(struct, tag, context) when is_bitstring(tag), do: add(struct, [tag], context)
  def add(struct, tags, context) do
    tag_list = tag_list(struct, context)
    new_tags = tags -- tag_list

    add_new_tags(struct, context, new_tags, tag_list)
  end

  defp add_new_tags(struct, context, [], tag_list), do: put_tags(struct, context, tag_list)
  defp add_new_tags(struct, context, new_tags, tag_list) do
    taggings = Enum.map(new_tags, fn(tag) ->
      generate_tagging(struct, tag, context)
    end)

    @repo.insert_all(Tagging, taggings)

    put_tags(struct, context, tag_list ++ new_tags)
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

  In the same way that add/3 it returns a struct

  """
  @spec remove(struct, tag, context) :: struct
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
  It searchs the associated tags for a specific
  context.

  You can pass as first argument an struct or a module (phoenix model)

  - With a struct: it returns the list of tags associated to that struct and context.
  - With a module: it returns all the tags associated to one module and context.
  """
  @spec tag_list(taggable, context) :: tag_list
  def tag_list(taggable, context \\ "tags")
  def tag_list(struct, context) when is_map(struct) do
    id = struct.id
    type = struct.__struct__ |> taggable_type

    TagletQuery.search_tags(context, type, id) |> @repo.all
  end
  def tag_list(model, context) do
    TagletQuery.search_tags(context, taggable_type(model)) |> @repo.all
  end

  @doc """
  Given a tag, module and context ('tag' by default), will find
  all the module resources associated to the given tag.

  You can pass a simple tag or a list of tags.
  """
  @spec tagged_with(tags, module, context) :: list
  def tagged_with(tags, model, context \\ "tags")
  def tagged_with(tag, model, context) when is_bitstring(tag), do: tagged_with([tag], model, context)
  def tagged_with(tags, model, context) do
    do_tags_search(model, tags, context) |> @repo.all
  end

  @doc """
  The same than tagged_with/3 but returns the query instead of db results.

  The purpose of this function is allow you to include it in your filter flow
  or perform actions like paginate the results.
  """
  def tagged_with_query(query, tag, context) when is_bitstring(tag), do: tagged_with_query(query, [tag], context)
  def tagged_with_query(query, tags, context \\ "tags") do
    do_tags_search(query, tags, context)
  end

  defp do_tags_search(queryable, tags, context) do
    %{from: {_source, schema}} = Ecto.Queryable.to_query(queryable)

    queryable
    |> TagletQuery.search_tagged_with(tags, context, taggable_type(schema))
  end

  defp taggable_type(module), do: module |> Module.split |> List.last
end
