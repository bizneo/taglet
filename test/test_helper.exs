Mix.Task.run "ecto.create", ~w(-r Taglet.Repo)
Mix.Task.run "ecto.migrate", ~w(-r Taglet.Repo)

Taglet.Repo.start_link

ExUnit.start()
