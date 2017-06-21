defmodule TagletTest do
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

  test "add/3 returns a list of associated tags with the new tags" do
    post = @repo.insert!(%Post{title: "hello world"})
    Taglet.add(post, "mytag")

    result = Taglet.add(post, ["tag1", "tag2"])

    assert result.tags == ["mytag", "tag1", "tag2"]
  end

  test "add/3 returns a list of associated tags with the new tag" do
    post = @repo.insert!(%Post{title: "hello world"})
    Taglet.add(post, "mytag")

    result = Taglet.add(post, "mytag2")

    assert result.tags == ["mytag", "mytag2"]
  end

  test "add/3 with context returns a diferent list for every context" do
    post = @repo.insert!(%Post{title: "hello world"})

    result1 = Taglet.add(post, "mytag1", "context1")
    result2 = Taglet.add(post, "mytag2", "context2")

    assert result1.context1 == ["mytag1"]
    assert result2.context2 == ["mytag2"]
  end

  test "remove/3 deletes a tag and returns a list of associated tags" do
    post = @repo.insert!(%Post{title: "hello world"})
    Taglet.add(post, "mytag")
    Taglet.add(post, "mytag2")
    Taglet.add(post, "mytag3")

    result = Taglet.remove(post, "mytag2")

    assert result.tags == ["mytag", "mytag3"]
  end

  test "remove/3 deletes a tag for a specific context and returns a list of associated tags" do
    post = @repo.insert!(%Post{title: "hello world"})
    Taglet.add(post, "mytag", "context1")
    Taglet.add(post, "mytag2", "context1")
    Taglet.add(post, "mytag3", "context2")

    result = Taglet.remove(post, "mytag2", "context1")

    assert result.context1 == ["mytag"]
  end

  test "tag_list/2 with struct as param returns a list of associated tags" do
    post = @repo.insert!(%Post{title: "hello world"})
    Taglet.add(post, "mytag")
    Taglet.add(post, "mytag2")

    result = Taglet.tag_list(post)

    assert result == ["mytag", "mytag2"]
  end

  test "tag_list/2 with struct returns a list of associated tags for a specific context" do
    post = @repo.insert!(%Post{title: "hello world"})
    Taglet.add(post, "mytag", "context")
    Taglet.add(post, "mytag2", "context")

    result = Taglet.tag_list(post, "context")

    assert result == ["mytag", "mytag2"]
  end

  test "tag_list/2 with module as param returns a list of tags related with one context and module" do
    post1 = @repo.insert!(%Post{title: "hello world"})
    post2 = @repo.insert!(%Post{title: "hello world2"})
    Taglet.add(post1, ["tag1", "tag2"])
    Taglet.add(post2, ["tag2", "tag3"])

    result = Taglet.tag_list(Post)

    assert result == ["tag1", "tag2", "tag3"]
  end

  #test "tagged_with/3 returns a list of structs associated to a tag" do
    #post1 = @repo.insert!(%Post{title: "hello world1"})
    #post2 = @repo.insert!(%Post{title: "hello world2"})
    #post3 = @repo.insert!(%Post{title: "hello world3"})
    #Taglet.add(post1, "tagged1")
    #Taglet.add(post2, "tagged1")
    #Taglet.add(post3, "tagged2")

    #result = Taglet.tagged_with("tagged1", Post)

    #assert result == [post1, post2]
  #end

  test "tagged_with_query/3 returns a query of structs associated to a tag" do
    post1 = @repo.insert!(%Post{title: "hello world1"})
    post2 = @repo.insert!(%Post{title: "hello world2"})
    post3 = @repo.insert!(%Post{title: "hello world3"})
    Taglet.add(post1, "tagged1")
    Taglet.add(post2, ["tagged1", "tagged2"])
    Taglet.add(post3, "tagged2")
    query = Post |> where(title: "hello world2")

    result = Taglet.tagged_with_query(Post, ["tagged1", "tagged2"]) |> @repo.all

    assert result == [post2]
  end
end
