defmodule Taglet.TagAsTest do
  use ExUnit.Case
  import Ecto.Query

  alias TagletPost, as: Post
  alias Taglet.{Tagging, Tag}

  @repo Taglet.RepoClient.repo

  doctest Taglet

  setup do
    @repo.delete_all(Post)
    @repo.delete_all(Tagging)
    @repo.delete_all(Tag)
    on_exit fn ->
      @repo.delete_all(Post)
      @repo.delete_all(Tagging)
      @repo.delete_all(Tag)
    end
    :ok
  end

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

end
