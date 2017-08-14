defmodule TagletTest do
  alias Ecto.Adapters.SQL
  alias TagletPost, as: Post
  alias Taglet.{Tagging, Tag}

  import Ecto.Query
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
  test "add/4 with a tag returns the struct with the new tag" do
    post = @repo.insert!(%Post{title: "hello world"})
    Taglet.add(post, "mytag")

    result = Taglet.add(post, "tag1")

    assert result.tags == ["mytag", "tag1"]
  end

  test "add/4 with a tag list returns the struct with the new tags" do
    post = @repo.insert!(%Post{title: "hello world"})
    Taglet.add(post, "mytag")

    result = Taglet.add(post, ["tag1", "tag2"])

    assert result.tags == ["mytag", "tag1", "tag2"]
  end

  test "add/4 with context returns a diferent list for every context" do
    post = @repo.insert!(%Post{title: "hello world"})

    result1 = Taglet.add(post, "mytag1", "context1")
    result2 = Taglet.add(post, "mytag2", "context2")

    assert result1.context1 == ["mytag1"]
    assert result2.context2 == ["mytag2"]
  end

  test "add/4 with repeated tag returns the same tags" do
    post = @repo.insert!(%Post{title: "hello world"})
    Taglet.add(post, "mytag")

    result = Taglet.add(post, "mytag")

    assert result.tags == ["mytag"]
  end

  test "add/4 with nil tag returns the same struct" do
    post = @repo.insert!(%Post{title: "hello world"})
    result = Taglet.add(post, nil)
    assert result == post
  end

  test "remove/4 deletes a tag and returns a list of associated tags" do
    post = @repo.insert!(%Post{title: "hello world"})
    Taglet.add(post, "mytag")
    Taglet.add(post, "mytag2")
    Taglet.add(post, "mytag3")

    result = Taglet.remove(post, "mytag2")

    assert result.tags == ["mytag", "mytag3"]
  end

  test "remove/4 deletes a tag for a specific context and returns a list of associated tags" do
    post = @repo.insert!(%Post{title: "hello world"})
    Taglet.add(post, "mytag", "context1")
    Taglet.add(post, "mytag2", "context1")
    Taglet.add(post, "mytag3", "context2")

    result = Taglet.remove(post, "mytag2", "context1")

    assert result.context1 == ["mytag"]
  end

  test "remove/4 does nothing for an unexistent tag" do
    post = @repo.insert!(%Post{title: "hello world"})
    Taglet.add(post, "mytag")
    Taglet.add(post, "mytag2")
    Taglet.add(post, "mytag3")

    result = Taglet.remove(post, "my2")

    assert result.tags == ["mytag", "mytag2", "mytag3"]
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

  test "tagged_with/4 returns a list of structs associated to a tag" do
    post1 = @repo.insert!(%Post{title: "hello world1"})
    post2 = @repo.insert!(%Post{title: "hello world2"})
    post3 = @repo.insert!(%Post{title: "hello world3"})
    Taglet.add(post1, "tagged1")
    Taglet.add(post2, "tagged1")
    Taglet.add(post3, "tagged2")

    result = Taglet.tagged_with("tagged1", Post)

    assert result == [post1, post2]
  end

  test "tagged_with_query/4 returns a query of structs associated to a tag" do
    post1 = @repo.insert!(%Post{title: "hello world1"})
    post2 = @repo.insert!(%Post{title: "hello world2"})
    post3 = @repo.insert!(%Post{title: "hello world3"})
    Taglet.add(post1, "tagged1")
    Taglet.add(post2, ["tagged1", "tagged2"])
    Taglet.add(post3, "tagged2")
    query = Post |> where(title: "hello world2")

    result = Taglet.tagged_with_query(query, ["tagged1", "tagged2"]) |> @repo.all

    assert result == [post2]
  end

  # Multi tenant test
  test "[multi tenant] add/4 with a tag returns the struct with the new tag" do
    post = @repo.insert!(%Post{title: "hello world"})
    Taglet.add(post, "mytag")

    result = Taglet.add(post, "tag1")

    assert result.tags == ["mytag", "tag1"]
  end

  test "[multi tenant] add/4 with a tag list returns the struct with the new tags" do
    post = @repo.insert!(%Post{title: "hello world"}, [prefix: @tenant_id])
    Taglet.add(post, "mytag", [prefix: @tenant_id])

    result = Taglet.add(post, ["tag1", "tag2"], [prefix: @tenant_id])

    assert result.tags == ["mytag", "tag1", "tag2"]
  end

  test "[multi tenant] add/4 with context returns a diferent list for every context" do
    post = @repo.insert!(%Post{title: "hello world"}, [prefix: @tenant_id])

    result1 = Taglet.add(post, "mytag1", "context1", [prefix: @tenant_id])
    result2 = Taglet.add(post, "mytag2", "context2", [prefix: @tenant_id])

    assert result1.context1 == ["mytag1"]
    assert result2.context2 == ["mytag2"]
  end

  test "[multi tenant] add/4 with repeated tag returns the same tags" do
    post = @repo.insert!(%Post{title: "hello world"}, [prefix: @tenant_id])
    Taglet.add(post, "mytag", [prefix: @tenant_id])

    result = Taglet.add(post, "mytag", [prefix: @tenant_id])

    assert result.tags == ["mytag"]
  end

  test "[multi tenant] add/4 with nil tag returns the same struct" do
    post = @repo.insert!(%Post{title: "hello world"}, [prefix: @tenant_id])
    result = Taglet.add(post, nil, [prefix: @tenant_id])
    assert result == post
  end

  test "[multi tenant] remove/4 deletes a tag and returns a list of associated tags" do
    post = @repo.insert!(%Post{title: "hello world"}, [prefix: @tenant_id])
    Taglet.add(post, "mytag", "tags", [prefix: @tenant_id])
    Taglet.add(post, "mytag2", "tags", [prefix: @tenant_id])
    Taglet.add(post, "mytag3", "tags", [prefix: @tenant_id])

    result = Taglet.remove(post, "mytag2", "tags", [prefix: @tenant_id])

    assert result.tags == ["mytag", "mytag3"]
  end

  test "[multi tenant] remove/4 deletes a tag for a specific context and returns a list of associated tags" do
    post = @repo.insert!(%Post{title: "hello world"}, [prefix: @tenant_id])
    Taglet.add(post, "mytag", "context1", [prefix: @tenant_id])
    Taglet.add(post, "mytag2", "context1", [prefix: @tenant_id])
    Taglet.add(post, "mytag3", "context2", [prefix: @tenant_id])

    result = Taglet.remove(post, "mytag2", "context1", [prefix: @tenant_id])

    assert result.context1 == ["mytag"]
  end

  test "[multi tenant] remove/4 does nothing for an unexistent tag" do
    post = @repo.insert!(%Post{title: "hello world"}, [prefix: @tenant_id])
    Taglet.add(post, "mytag", "tags", [prefix: @tenant_id])
    Taglet.add(post, "mytag2", "tags", [prefix: @tenant_id])
    Taglet.add(post, "mytag3", "tags", [prefix: @tenant_id])

    result = Taglet.remove(post, "my2", "tags", [prefix: @tenant_id])

    assert result.tags() == ["mytag", "mytag2", "mytag3"]
  end

  test "[multi tenant] tag_list/2 with struct as param returns a list of associated tags" do
    post = @repo.insert!(%Post{title: "hello world"}, [prefix: @tenant_id])
    Taglet.add(post, "mytag", "tags", [prefix: @tenant_id])
    Taglet.add(post, "mytag2", "tags", [prefix: @tenant_id])

    result = Taglet.tag_list(post, "tags", [prefix: @tenant_id])

    assert result == ["mytag", "mytag2"]
  end

  test "[multi tenant] tag_list/2 with struct returns a list of associated tags for a specific context" do
    post = @repo.insert!(%Post{title: "hello world"}, [prefix: @tenant_id])
    Taglet.add(post, "mytag", "context", [prefix: @tenant_id])
    Taglet.add(post, "mytag2", "context", [prefix: @tenant_id])

    result = Taglet.tag_list(post, "context", [prefix: @tenant_id])

    assert result == ["mytag", "mytag2"]
  end

  test "[multi tenant] tag_list/2 with module as param returns a list of tags related with one context and module" do
    post1 = @repo.insert!(%Post{title: "hello world"}, [prefix: @tenant_id])
    post2 = @repo.insert!(%Post{title: "hello world2"}, [prefix: @tenant_id])
    Taglet.add(post1, ["tag1", "tag2"], "tags", [prefix: @tenant_id])
    Taglet.add(post2, ["tag2", "tag3"], "tags", [prefix: @tenant_id])

    result = Taglet.tag_list(Post, "tags", [prefix: @tenant_id])

    assert result == ["tag1", "tag2", "tag3"]
  end

  test "[multi tenant] tagged_with/4 returns a list of structs associated to a tag" do
    post1 = @repo.insert!(%Post{title: "hello world1"}, [prefix: @tenant_id])
    post2 = @repo.insert!(%Post{title: "hello world2"}, [prefix: @tenant_id])
    post3 = @repo.insert!(%Post{title: "hello world3"}, [prefix: @tenant_id])
    Taglet.add(post1, "tagged1", "tags", [prefix: @tenant_id])
    Taglet.add(post2, "tagged1", "tags", [prefix: @tenant_id])
    Taglet.add(post3, "tagged2", "tags", [prefix: @tenant_id])
    post1 = @repo.get(Post, 1, [prefix: @tenant_id])
    post2 = @repo.get(Post, 2, [prefix: @tenant_id])

    result = Taglet.tagged_with("tagged1", Post, "tags", [prefix: @tenant_id])

    assert result == [post1, post2]
  end

  test "[multi tenant] tagged_with_query/4 returns a query of structs associated to a tag" do
    post1 = @repo.insert!(%Post{title: "hello world1"}, [prefix: @tenant_id])
    post2 = @repo.insert!(%Post{title: "hello world2"}, [prefix: @tenant_id])
    post3 = @repo.insert!(%Post{title: "hello world3"}, [prefix: @tenant_id])
    Taglet.add(post1, "tagged1", "tags", [prefix: @tenant_id])
    Taglet.add(post2, ["tagged1", "tagged2"], "tags", [prefix: @tenant_id])
    Taglet.add(post3, "tagged2", "tags", [prefix: @tenant_id])
    query = Post |> where(title: "hello world2")
    post2 = @repo.get(Post, 2, [prefix: @tenant_id])

    result =
      Taglet.tagged_with_query(query, ["tagged1", "tagged2"])
      |> @repo.all([prefix: @tenant_id])

    assert result == [post2]
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
