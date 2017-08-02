defmodule Taglet do
  alias Taglet.{Tagging, Tag, TagletQuery}
  import Taglet.RepoClient

  @moduledoc """
  Documentation for Taglet.
  Taglet allows you to manage tags associated to your records.

  Please read README.md to get more info about how to use that
  package.
  """

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
  def add(struct, nil, _context), do: struct
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

    repo().insert_all(Tagging, taggings)

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
        |> TagletQuery.get_tags_association(get_or_create(tag), context)
        |> repo().delete_all

        remove_from_tag_if_unused(tag)
        put_tags(struct, context, List.delete(tag_list, tag))
      false ->
        put_tags(struct, context, tag_list)
    end

  end

  # Remove tag from Tag table if it's unused
  defp remove_from_tag_if_unused(nil), do: nil
  defp remove_from_tag_if_unused(tag) do
    tag = repo().get_by(Tag, name: tag)
    if tag do
      TagletQuery.count_tagging_by_tag_id(tag.id)
      |> repo().one
      |> case do
        0 -> repo().delete(tag)
        _ -> nil
      end
    end
  end

  defp get_or_create(tag) do
    case repo().get_by(Tag, name: tag) do
      nil -> repo().insert!(%Tag{name: tag})
      tag_resource -> tag_resource
    end
  end

  defp put_tags(struct, context, tags) do
    Map.put(struct, String.to_atom(context), tags)
  end

  @doc """
  Rename the tag name by a new one. This actions has effect only
  in the context specificied.

  If the old_tag does not exist return nil.
  """
  @spec rename(struct, tag, tag, context) :: nil | struct
  def rename(struct, old_tag_name, new_tag_name, context) do
    case repo().get_by(Tag, name: old_tag_name) do
      nil -> nil
      tag -> rename_tag(struct, tag, new_tag_name, context)
    end
  end

  defp rename_tag(struct, old_tag, new_tag_name, context) do
    case taggings_by_tag_id(old_tag.id) do
      0 ->
        #If the old tag is NOT in Tagging we have only to rename its `name`
        #in Tag table.
        Tag.changeset(old_tag, %{name: new_tag_name})
        |> repo().update
      _ ->
        #In this case we have to get or create a new Tag, and uptade all relations
        # context - taggable_type with the new_tag.id
        new_tag = get_or_create(new_tag_name)

        TagletQuery.get_tags_association(struct, old_tag, context)
        |> repo().update_all(set: [tag_id: new_tag.id])

        if taggings_by_tag_id(old_tag.id) == 0 do
          repo().delete(old_tag)
        end
    end
  end

  #Return the number of entries in Tagging with the tag_id passed as param.
  defp taggings_by_tag_id(tag_id) do
    TagletQuery.count_tagging_by_tag_id(tag_id)
    |> repo().one
  end

  @doc """
  It searchs the associated tags for a specific
  context.

  You can pass as first argument an struct or a module (phoenix model)

  - With a struct: it returns the list of tags associated to that struct and context.
  - With a module: it returns all the tags associated to one module and context.
  """
  @spec tag_list(taggable, context) :: tag_list
  def tag_list(taggable, context \\ "tags") do
    taggable
    |> tag_list_queryable(context)
    |> repo().all
  end

  @doc """
  It works exactly like tag_list but return a queryable

  You can pass as first argument an struct or a module (phoenix model)

  - With a struct: it returns the list of tags associated to that struct and context.
  - With a module: it returns all the tags associated to one module and context.
  """
  @spec tag_list_queryable(taggable, context) :: Ecto.Queryable.t
  def tag_list_queryable(taggable, context \\ "tags")
  def tag_list_queryable(struct, context) when is_map(struct) do
    id = struct.id
    type = struct.__struct__ |> taggable_type

    TagletQuery.search_tags(context, type, id)
  end
  def tag_list_queryable(model, context) do
    TagletQuery.search_tags(context, taggable_type(model))
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
    do_tags_search(model, tags, context) |> repo().all
  end

  @doc """
  The same than tagged_with/3 but returns the query instead of db results.

  The purpose of this function is allow you to include it in your filter flow
  or perform actions like paginate the results.
  """
  def tagged_with_query(query, tags, context \\ "tags")
  def tagged_with_query(query, tag, context) when is_bitstring(tag), do: tagged_with_query(query, [tag], context)
  def tagged_with_query(query, tags, context) do
    do_tags_search(query, tags, context)
  end

  defp do_tags_search(queryable, tags, context) do
    %{from: {_source, schema}} = Ecto.Queryable.to_query(queryable)

    queryable
    |> TagletQuery.search_tagged_with(tags, context, taggable_type(schema))
  end

  defp taggable_type(module), do: module |> Module.split |> List.last
end
