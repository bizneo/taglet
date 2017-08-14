# Taglet

[![CircleCI](https://circleci.com/gh/bizneo/taglet/tree/master.svg?style=svg)](https://circleci.com/gh/bizneo/taglet/tree/master)

Taglet allows you to manage tags associated to your records.

It also allows you to specify various contexts

## Installation

  1. Add `taglet` to your list of dependencies in `mix.exs`:

  ```elixir
  def deps do
    [{:taglet, "~> 0.6.0"}]
  end
  ```

  2. Configure Taglet to use your repo in `config/config.exs`:

  ```elixir
  config :taglet, repo: ApplicationName.Repo
  ```

  3. Install your dependencies:

  ```mix deps.get```

  4. Generate the migrations:

  ```mix taglet.install```

  5. Run the migrations:

  ```mix ecto.migrate```

## Include it in your models

Now, you can use the library in your models.

You should add the next line to your taggable model:

`use Taglet.TagAs, :tag_context_name`

i.e.:

  ```elixir
  defmodule Post do
    use Ecto.Schema
    use Taglet.TagAs, :tags
    use Taglet.TagAs, :categories

    import Ecto.Changeset

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
  ```
As you can see, we have included two different contexts, tags and
categories

Now we can use a set of metaprogrammed functions:

`Post.add_category(struct, tag)` - Passing a persisted struct will
allow you to associate a new tag

`Post.add_categories(struct, tags)` - Passing a persisted struct will
allow you to associate a new list of tags

`Post.add_category(tag)` - Add a Tag without associate it to a persisted struct,
this allow you have tags availables in the context. Example using `Post.categories`

`Post.remove_category(struct, tag)` - Will allow you to remove the relation `struct - tag`,
but the tag will persist.

`Post.remove_category(tag)` - Will allow you to remove a tag in the context `Post - category`. Tag and relations with Post will be deleted.

`Post.rename_category(old_tag, new_tag)` - Will allow you to rename the tag name.

`Post.categories_list(struct)` - List all associated tags with the given
struct

`Post.categories` - List all associated tags with the module

`Post.categories_queryable` - Same as `Post.categories` but it returns a `queryable` instead of a list.

`Post.tagged_with_category(tag)` - Search for all resources tagged with
the given tag

`Post.tagged_with_categories(tags)` - Search for all resources tagged
with the given list tag

`Post.tagged_with_query_category(queryable, tags)` - Allow to
concatenate ecto queries and return the query.

`Post.tagged_with_query_categories(queryable, tags)` - Same than previous function but allow to receive a list of tags


## Working with functions

If you want you can use directly a set of functions to play with tags:

[`Taglet.add/4`](https://hexdocs.pm/taglet/Taglet.html#add/4)

[`Taglet.remove/4`](https://hexdocs.pm/taglet/Taglet.html#remove/4)

[`Taglet.rename/5`](https://hexdocs.pm/taglet/Taglet.html#rename/5)

[`Taglet.tag_list/3`](https://hexdocs.pm/taglet/Taglet.html#tag_list/3)

[`Taglet.tag_list_queryable/2`](https://hexdocs.pm/taglet/Taglet.html#tag_list_queryable/2)

[`Taglet.tagged_with/4`](https://hexdocs.pm/taglet/Taglet.html#tagged_with/4)

[`Taglet.tagged_with_query/3`](https://hexdocs.pm/taglet/Taglet.html#tagged_with_query/3)
