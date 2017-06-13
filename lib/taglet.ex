defmodule Taglet do
  import Ecto.Query
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
  @spec add(struct, tags, context) :: tag_list
  def add(struct, tags, context \\ "tag")
  def add(struct, tags, context) when is_list(tags) do
    tag_list = tag_list(struct, context)
    new_tags = tags -- tag_list

    case new_tags do
      [] ->
        tag_list
      new_tags ->
        taggings = Enum.map(new_tags, fn(tag) ->
          generate_tagging(struct, tag, context)
        end)

        @repo.insert_all(Tagging, taggings)

        tag_list ++ new_tags
    end

  end
  def add(struct, tag, context) do
    tag_list = tag_list(struct, context)

    case tag in tag_list do
      true  -> tag_list
      false ->
        %Tagging{}
        |> Tagging.changeset(generate_tagging(struct, tag, context))
        |> @repo.insert!

        List.insert_at(tag_list, -1, tag)
    end
  end

  defp get_or_create(tag) do
    case @repo.get_by(Tag, name: tag) do
      nil -> @repo.insert!(%Tag{name: tag})
      tag_resource -> tag_resource
    end
  end

  defp generate_tagging(struct, tag, context) do
    tag_resource = get_or_create(tag)

    %{
      taggable_id: struct.id,
      taggable_type: struct.__struct__ |> Module.split |> List.last,
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
  def remove(struct, tag, context \\ "tag") do
    tag_list = tag_list(struct, context)

    case tag in tag_list do
      true ->
        struct
        |> get_association(get_or_create(tag), context)
        |> @repo.delete!

        List.delete(tag_list, tag)
      false -> tag_list
    end
  end

  defp get_association(struct, tag_resource, context) do
    @repo.get_by(Tagging,
      taggable_id: struct.id,
      taggable_type: struct.__struct__ |> Module.split |> List.last,
      context: context,
      tag_id: tag_resource.id
    )
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

  @doc """
  Given a tag, model and context ('tag' by default), will find
  all the model resources associated to the given tag.
  """
  @spec tagged_with(tag, module, context) :: list
  def tagged_with(tag, model, context \\ "tag") do
    type = model |> Module.split |> List.last

    model
    |> join(:right, [m], tg in Tagging,
      tg.taggable_type == ^type
      and
      tg.context == ^context
    )
    |> join(:inner, [m, tg], t in Tag,
      t.id == tg.tag_id
      and
      t.name == ^tag
    )
    |> where([m, tg, t], m.id == tg.taggable_id)
    |> @repo.all
  end
end
