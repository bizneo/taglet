defmodule Taglet.ModelManagerTest do
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
end
