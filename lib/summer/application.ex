defmodule Summer.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {DNSCluster, query: Application.get_env(:summer, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Summer.PubSub},
      SummerWeb.Endpoint,
      Summer.State
    ]

    opts = [strategy: :one_for_one, name: Summer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    SummerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
