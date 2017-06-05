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

  test "add/3 returns a list of associated tags with the new tag" do
    post = @repo.insert!(%Post{title: "hello world"})
    Taglet.add(post, "mytag")

    result = Taglet.add(post, "mytag2")

    assert result == ["mytag", "mytag2"]
  end

  test "add/3 with context returns a diferent list for every context" do
    post = @repo.insert!(%Post{title: "hello world"})

    result1 = Taglet.add(post, "mytag1", "context1")
    result2 = Taglet.add(post, "mytag2", "context2")

    assert result1 == ["mytag1"]
    assert result2 == ["mytag2"]
  end

  test "tag_list/2 returns a list of associated tags" do
    post = @repo.insert!(%Post{title: "hello world"})
    Taglet.add(post, "mytag")
    Taglet.add(post, "mytag2")

    result = Taglet.tag_list(post)

    assert result == ["mytag", "mytag2"]
  end

  test "tag_list/2 returns a list of associated tags for a specific context" do
    post = @repo.insert!(%Post{title: "hello world"})
    Taglet.add(post, "mytag", "context")
    Taglet.add(post, "mytag2", "context")

    result = Taglet.tag_list(post, "context")

    assert result == ["mytag", "mytag2"]
  end
end
