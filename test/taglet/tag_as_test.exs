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

  test "using the module allows to add a tag and list it" do
    post = @repo.insert!(%Post{title: "hello world"})
    Post.add_category(post, "mycategory")

    result = Post.categories_list(post)

    assert result == ["mycategory"]
  end

  test "using the module allows to add a tag and list it for different contexts" do
    post = @repo.insert!(%Post{title: "hello world"})
    Post.add_category(post, "mycategory")
    Post.add_tag(post, "mytag")

    tag_result      = Post.tags_list(post)
    category_result = Post.categories_list(post)

    assert tag_result      == ["mytag"]
    assert category_result == ["mycategory"]
  end

  test "using the module allows to remove a tag and list it" do
    post = @repo.insert!(%Post{title: "hello world"})
    Post.add_category(post, "mycategory")

    result = Post.remove_category(post, "mycategory")

    assert result.categories == []
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
end
