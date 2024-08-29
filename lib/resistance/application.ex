# 
#   Copyright (C) 2024  Bruno Flávio Ferreira
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU Affero General Public License as published
#   by the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU Affero General Public License for more details.
#
#   You should have received a copy of the GNU Affero General Public License
#   along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
defmodule Resistance.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ResistanceWeb.Telemetry,
      Resistance.Repo,
      {DNSCluster, query: Application.get_env(:resistance, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Resistance.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Resistance.Finch},
      # Start a worker by calling: Resistance.Worker.start_link(arg)
      # {Resistance.Worker, arg},
      # Start to serve requests, typically the last entry
      ResistanceWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Resistance.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ResistanceWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
