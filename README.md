[![CircleCI](https://circleci.com/gh/bizneo/taglet/tree/master.svg?style=svg)](https://circleci.com/gh/bizneo/taglet/tree/master)

# Taglet

Taglet allows you to manage tags associated to your records.

It also allows you to specify various contexts 

## Installation

  1. Add `taglet` to your list of dependencies in `mix.exs`:

  ```elixir
  def deps do
    [{:taglet, github: "bizneo/taglet"}]
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


Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/taglet](https://hexdocs.pm/taglet).
