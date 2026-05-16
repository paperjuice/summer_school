defmodule Summer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      SummerWeb.Telemetry,
      #      Summer.Repo,
      {DNSCluster, query: Application.get_env(:summer, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Summer.PubSub},
      # Start a worker by calling: Summer.Worker.start_link(arg)
      # {Summer.Worker, arg},
      # Start to serve requests, typically the last entry
      SummerWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Summer.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SummerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
