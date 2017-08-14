defmodule Taglet.TagAsTest do
  alias Ecto.Adapters.SQL
  alias TagletPost, as: Post
  alias Taglet.{Tagging, Tag}

  import Ecto.Query
  import Mix.Ecto, only: [build_repo_priv: 1]

  use ExUnit.Case

  @repo       Taglet.RepoClient.repo
  @tenant_id  "example_tenant"

  doctest Taglet

  setup do
    # Regular test
    @repo.delete_all(Post)
    @repo.delete_all(Tagging)
    @repo.delete_all(Tag)

    # Multi tenant test
    setup_tenant()

    on_exit fn ->
      # Regular test
      @repo.delete_all(Post)
      @repo.delete_all(Tagging)
      @repo.delete_all(Tag)

      # Multi tenant test
      setup_tenant()
    end
    :ok
  end

  # Regular test
  test "using the module allows to add tags and list it" do
    post = @repo.insert!(%Post{title: "hello world"})

    result = Post.add_categories(post, ["mycategory", "yourcategory"])

    assert result.categories == ["mycategory", "yourcategory"]
  end

  test "using the module allows to add tags and list it as a queryable" do
    post = @repo.insert!(%Post{title: "hello world"})

    Post.add_categories(post, ["mycategory", "yourcategory"])
    queryable = Post.categories_queryable

    assert queryable.__struct__ == Ecto.Query
    assert queryable |> @repo.all == ["mycategory", "yourcategory"]
  end

  test "using the module allows to add a tag and list it" do
    post = @repo.insert!(%Post{title: "hello world"})
    Post.add_category(post, "mycategory")

    result = Post.category_list(post)

    assert result == ["mycategory"]
  end

  test "using the module allows to add a tag and list it for different contexts" do
    post = @repo.insert!(%Post{title: "hello world"})
    Post.add_category(post, "mycategory")
    Post.add_tag(post, "mytag")

    tag_result      = Post.tag_list(post)
    category_result = Post.category_list(post)

    assert tag_result      == ["mytag"]
    assert category_result == ["mycategory"]
  end

  test "using the module allows to add a tag and list it as queryable for different contexts" do
    post = @repo.insert!(%Post{title: "hello world"})
    Post.add_category(post, "mycategory")
    Post.add_tag(post, "mytag")

    tag_queryable      = Post.tags_queryable
    category_queryable = Post.categories_queryable

    assert tag_queryable.__struct__      == Ecto.Query
    assert category_queryable.__struct__ == Ecto.Query

    assert tag_queryable |> @repo.all      == ["mytag"]
    assert category_queryable |> @repo.all == ["mycategory"]
  end

  test "Remove only a Tag relation" do
    post1 = @repo.insert!(%Post{title: "Post1"})
    post2 = @repo.insert!(%Post{title: "Post2"})
    #We add a category without relations
    Post.add_category("public")
    #Now we add 2 new entries in Tagging relating with different tag_id
    Post.add_category(post1, "public")
    Post.add_category(post2, "public")
    #Remove only the relation with post1
    result = Post.remove_category(post1, "public")
    # Tag still exits but there are 2 relations in Tagging that represent
    # a general relation with Post - categories and one for post2
    assert result.categories == []
    assert Post.categories == ["public"]
    assert Tag |> @repo.all |> length == 1
    assert Tagging |> @repo.all |> length == 2
  end

  test "It is possible to remove a Tag and all its relations" do
    post = @repo.insert!(%Post{title: "Post1"})
    #We add a category without relations
    Post.add_category("public")
    #Now we add a new entry in Tagging relating Tag and taggable_id
    Post.add_category(post, "public")
    #Remove everything about public - Post - categories
    result = Post.remove_category("public")

    assert result.categories == []
    assert Tag |> @repo.all == []
    assert Tagging |> @repo.all == []
  end

  test "Remove a generic Tag keep other contexts" do
    post = @repo.insert!(%Post{title: "Post1"})
    #We add two categories in a general way (without relations)
    Post.add_category("public")
    Post.add_tag("private")
    #Now we add 2 new entries in Tagging relating Tag and taggable_id
    Post.add_category(post, "public")
    Post.add_tag(post, "private")
    #At this point we have 2 tags in Tag, and 4 entries in Tagging
    result = Post.remove_category("public")

    #Remove everything about public - Post - categories
    assert result.categories == []
    assert Post.categories == []
    assert Post.tags == ["private"]
    assert Tagging |> @repo.all  |> length == 2
  end

  test "using the module allows to search for all created tags for a context" do
    post1 = @repo.insert!(%Post{title: "hello world"})
    post2 = @repo.insert!(%Post{title: "hello world2"})
    Taglet.add(post1, ["tag1", "tag2"])
    Taglet.add(post2, ["tag2", "tag3"])

    result = Post.tags

    assert result == ["tag1", "tag2", "tag3"]
  end

  test "using the module allows to search for tagged resources" do
    post1 = @repo.insert!(%Post{title: "hello world1"})
    post2 = @repo.insert!(%Post{title: "hello world2"})
    post3 = @repo.insert!(%Post{title: "hello world3"})
    Post.add_category(post1, "tagged1")
    Post.add_category(post2, "tagged1")
    Post.add_category(post3, "tagged2")

    result = Post.tagged_with_category("tagged1")

    assert result == [post1, post2]
  end

  test "using the module allows to build a query to search for tagged resources" do
    post1 = @repo.insert!(%Post{title: "hello world1"})
    post2 = @repo.insert!(%Post{title: "hello world2"})
    post3 = @repo.insert!(%Post{title: "hello world3"})
    Post.add_category(post1, "tagged1")
    Post.add_category(post2, "tagged1")
    Post.add_category(post3, "tagged2")
    query = Post |> where(title: "hello world1")

    result = Post.tagged_with_query_category(query, "tagged1") |> @repo.all

    assert result == [post1]
  end

  test "Update a tag name without relations" do

    Post.add_category(["public"])
    assert Post.categories == ["public"]

    #Now we add 2 new entries in Tagging relating Tag and taggable_id
    Post.rename_category("public", "public_post")

    assert Post.categories == ["public_post"]
    assert Tag |> @repo.all  |> length == 1
    assert Tagging |> @repo.all  |> length == 1
  end

  test "Update a tag name with relations and different contexts" do
    Post.add_category(["public", "private"])
    Post.add_tags(["private"])

    assert Post.categories == ["private", "public"]
    assert Post.tags == ["private"]

    #Now we add 2 new entries in Tagging relating Tag and taggable_id
    Post.rename_category("private", "private_category")

    assert Post.categories == ["private_category", "public"]
    assert Post.tags == ["private"]
    assert Tag |> @repo.all  |> length == 3
    assert Tagging |> @repo.all  |> length == 3
  end

  # Multi tenant test
  test "[multi tenant] using the module allows to add tags and list it" do
    post = @repo.insert!(%Post{title: "hello world"}, [prefix: @tenant_id])

    result = Post.add_categories(post, ["mycategory", "yourcategory"], [prefix: @tenant_id])

    assert result.categories == ["mycategory", "yourcategory"]
  end

  test "[multi tenant] using the module allows to add tags and list it as a queryable" do
    post = @repo.insert!(%Post{title: "hello world"}, [prefix: @tenant_id])

    Post.add_categories(post, ["mycategory", "yourcategory"], [prefix: @tenant_id])
    queryable = Post.categories_queryable

    assert queryable.__struct__ == Ecto.Query
    assert queryable |> @repo.all([prefix: @tenant_id]) == ["mycategory", "yourcategory"]
    assert queryable |> @repo.all == []
  end

  test "[multi tenant] using the module allows to add a tag and list it" do
    post = @repo.insert!(%Post{title: "hello world"}, [prefix: @tenant_id])
    Post.add_category(post, "mycategory", [prefix: @tenant_id])

    result = Post.category_list(post, [prefix: @tenant_id])

    assert result == ["mycategory"]
  end

  test "[multi tenant] using the module allows to add a tag and list it for different contexts" do
    post = @repo.insert!(%Post{title: "hello world"}, [prefix: @tenant_id])
    Post.add_category(post, "mycategory", [prefix: @tenant_id])
    Post.add_tag(post, "mytag", [prefix: @tenant_id])

    tag_result      = Post.tag_list(post, [prefix: @tenant_id])
    category_result = Post.category_list(post, [prefix: @tenant_id])

    assert tag_result      == ["mytag"]
    assert category_result == ["mycategory"]
  end

  test "[multi tenant] using the module allows to add a tag and list it as queryable for different contexts" do
    post = @repo.insert!(%Post{title: "hello world"}, [prefix: @tenant_id])
    Post.add_category(post, "mycategory", [prefix: @tenant_id])
    Post.add_tag(post, "mytag", [prefix: @tenant_id])

    tag_queryable      = Post.tags_queryable
    category_queryable = Post.categories_queryable

    assert tag_queryable.__struct__      == Ecto.Query
    assert category_queryable.__struct__ == Ecto.Query

    assert tag_queryable |> @repo.all      == []
    assert category_queryable |> @repo.all == []
    assert tag_queryable |> @repo.all([prefix: @tenant_id])      == ["mytag"]
    assert category_queryable |> @repo.all([prefix: @tenant_id]) == ["mycategory"]
  end

  test "[multi tenant] Remove only a Tag relation" do
    post1 = @repo.insert!(%Post{title: "Post1"}, [prefix: @tenant_id])
    post2 = @repo.insert!(%Post{title: "Post2"}, [prefix: @tenant_id])
    #We add a category without relations
    Post.add_category("public", [prefix: @tenant_id])
    #Now we add 2 new entries in Tagging relating with different tag_id
    Post.add_category(post1, "public", [prefix: @tenant_id])
    Post.add_category(post2, "public", [prefix: @tenant_id])
    #Remove only the relation with post1
    result = Post.remove_category(post1, "public", [prefix: @tenant_id])
    # Tag still exits but there are 2 relations in Tagging that represent
    # a general relation with Post - categories and one for post2
    assert result.categories == []
    assert Post.categories([prefix: @tenant_id]) == ["public"]
    assert Tag |> @repo.all |> length == 0
    assert Tagging |> @repo.all |> length == 0
    assert Tag |> @repo.all([prefix: @tenant_id]) |> length == 1
    assert Tagging |> @repo.all([prefix: @tenant_id]) |> length == 2
  end

  test "[multi tenant] It is possible to remove a Tag and all its relations" do
    post = @repo.insert!(%Post{title: "Post1"}, [prefix: @tenant_id])
    #We add a category without relations
    Post.add_category("public", [prefix: @tenant_id])
    #Now we add a new entry in Tagging relating Tag and taggable_id
    Post.add_category(post, "public", [prefix: @tenant_id])
    #Remove everything about public - Post - categories
    result = Post.remove_category("public", [prefix: @tenant_id])

    assert result.categories == []
    assert Tag |> @repo.all([prefix: @tenant_id]) == []
    assert Tagging |> @repo.all([prefix: @tenant_id]) == []
  end

  test "[multi tenant] Remove a generic Tag keep other contexts" do
    post = @repo.insert!(%Post{title: "Post1"}, [prefix: @tenant_id])
    #We add two categories in a general way (without relations)
    Post.add_category("public", [prefix: @tenant_id])
    Post.add_tag("private", [prefix: @tenant_id])
    #Now we add 2 new entries in Tagging relating Tag and taggable_id
    Post.add_category(post, "public", [prefix: @tenant_id])
    Post.add_tag(post, "private", [prefix: @tenant_id])
    #At this point we have 2 tags in Tag, and 4 entries in Tagging
    result = Post.remove_category("public", [prefix: @tenant_id])

    #Remove everything about public - Post - categories
    assert result.categories == []
    assert Post.categories([prefix: @tenant_id]) == []
    assert Post.tags([prefix: @tenant_id]) == ["private"]
    assert Tagging |> @repo.all([prefix: @tenant_id]) |> length == 2
  end

  test "[multi tenant] using the module allows to search for all created tags for a context" do
    post1 = @repo.insert!(%Post{title: "hello world"}, [prefix: @tenant_id])
    post2 = @repo.insert!(%Post{title: "hello world2"}, [prefix: @tenant_id])
    Taglet.add(post1, ["tag1", "tag2"], [prefix: @tenant_id])
    Taglet.add(post2, ["tag2", "tag3"], [prefix: @tenant_id])

    result = Post.tags([prefix: @tenant_id])

    assert result == ["tag1", "tag2", "tag3"]
  end

  test "[multi tenant] using the module allows to search for tagged resources" do
    post1 = @repo.insert!(%Post{title: "hello world1"}, [prefix: @tenant_id])
    post2 = @repo.insert!(%Post{title: "hello world2"}, [prefix: @tenant_id])
    post3 = @repo.insert!(%Post{title: "hello world3"}, [prefix: @tenant_id])
    Post.add_category(post1, "tagged1", [prefix: @tenant_id])
    Post.add_category(post2, "tagged1", [prefix: @tenant_id])
    Post.add_category(post3, "tagged2", [prefix: @tenant_id])
    post1 = @repo.get(Post, 1, [prefix: @tenant_id])
    post2 = @repo.get(Post, 2, [prefix: @tenant_id])

    result = Post.tagged_with_category("tagged1", [prefix: @tenant_id])

    assert result == [post1, post2]
  end

  test "[multi tenant] using the module allows to build a query to search for tagged resources" do
    post1 = @repo.insert!(%Post{title: "hello world1"}, [prefix: @tenant_id])
    post2 = @repo.insert!(%Post{title: "hello world2"}, [prefix: @tenant_id])
    post3 = @repo.insert!(%Post{title: "hello world3"}, [prefix: @tenant_id])
    Post.add_category(post1, "tagged1", [prefix: @tenant_id])
    Post.add_category(post2, "tagged1", [prefix: @tenant_id])
    Post.add_category(post3, "tagged2", [prefix: @tenant_id])
    query = Post |> where(title: "hello world1")
    post1 = @repo.get(Post, 1, [prefix: @tenant_id])

    result = Post.tagged_with_query_category(query, "tagged1") |> @repo.all([prefix: @tenant_id])

    assert result == [post1]
  end

  test "[multi tenant] Update a tag name without relations" do

    Post.add_category(["public"], [prefix: @tenant_id])
    assert Post.categories([prefix: @tenant_id]) == ["public"]

    #Now we add 2 new entries in Tagging relating Tag and taggable_id
    Post.rename_category("public", "public_post", [prefix: @tenant_id])

    assert Post.categories == []
    assert Tag |> @repo.all |> length == 0
    assert Tagging |> @repo.all |> length == 0
    assert Post.categories([prefix: @tenant_id]) == ["public_post"]
    assert Tag |> @repo.all([prefix: @tenant_id]) |> length == 1
    assert Tagging |> @repo.all([prefix: @tenant_id]) |> length == 1
  end

  test "[multi tenant] Update a tag name with relations and different contexts" do
    Post.add_categories(["public", "private"], [prefix: @tenant_id])
    Post.add_tags(["private"], [prefix: @tenant_id])

    assert Post.categories([prefix: @tenant_id]) == ["private", "public"]
    assert Post.tags([prefix: @tenant_id]) == ["private"]

    #Now we add 2 new entries in Tagging relating Tag and taggable_id
    Post.rename_category("private", "private_category", [prefix: @tenant_id])

    assert Post.categories == []
    assert Post.tags == []
    assert Tag |> @repo.all |> length == 0
    assert Tagging |> @repo.all |> length == 0
    assert Post.categories([prefix: @tenant_id]) == ["private_category", "public"]
    assert Post.tags([prefix: @tenant_id]) == ["private"]
    assert Tag |> @repo.all([prefix: @tenant_id]) |> length == 3
    assert Tagging |> @repo.all([prefix: @tenant_id]) |> length == 3
  end

  # Aux functions
  defp setup_tenant do
    migrations_path = Path.join(build_repo_priv(@repo), "migrations")

    # Drop the previous tenant to reset the data
    SQL.query(@repo, "DROP SCHEMA \"#{@tenant_id}\" CASCADE", [])

    # Create new tenant
    SQL.query(@repo, "CREATE SCHEMA \"#{@tenant_id}\"", [])
    Ecto.Migrator.run(@repo, migrations_path, :up, [prefix: @tenant_id, all: true])
  end
end
