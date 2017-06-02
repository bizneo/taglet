defmodule Taglet.RepoClient do
  @doc """
  Gets the configured repo module or defaults to Repo if none configured
  """
  def repo, do: Application.get_env(:taglet, :repo, Repo)
end
