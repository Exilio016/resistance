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
defmodule ResistanceWeb.GamesLive do
  alias Phoenix.PubSub
  alias Phoenix.JS
  use ResistanceWeb, :live_view

  def mount(_params, _session, socket) do
    if connected?(socket), do: PubSub.subscribe(Resistance.PubSub, "game-list")
    
    games = Resistance.Games.list_games_in_lobby()
    socket = assign(socket, games: games)
    {:ok, socket}
  end

  def handle_info("game-update", socket) do 
    {:noreply, assign(socket, games: Resistance.Games.list_games_in_lobby())}
  end

  def render(assigns) do 
    ~H"""
    <h2 class="text-xl text-center text-neutral-100"> Find a game! </h2>
    <table class="min-w-full divide-y divide-neutral-700 text-neutral-100 overflow-y-scroll">
      <thead>
        <tr>
          <th scope="col" class="px-6 py-1 uppercase font-medium text-start text-neutral-500">Name</th>
          <th scope="col" class="px-6 py-1 uppercase font-medium text-end text-neutral-500">Players</th>
        </tr>
      </thead>
      <tbody>
        <%= for game <- @games do %>
          <tr id={"game-#{game.id}"} phx-click={JS.dispatch("games:select-game", to: "#game-#{game.id}")} class="hover:bg-neutral-700">
            <td class="px-6 py-2 text-start"><%= game.name %></td>
            <td class="px-6 py-2 text-end"><%= length(game.players) %></td>
          </tr>
        <% end %>
      </tbody>
    </table>
    <div class="flex relative justify-between mx-6 my-4">
      <a href="/create" class="border border-transparent rounded-lg px-4 py-2 bg-emerald-900 hover:bg-emerald-700">Create Game</a>
      <button phx-click={JS.dispatch("games:join-game")} class="border border-transparent rounded-lg px-4 py-2 bg-emerald-900 hover:bg-emerald-700">Join Game</button>
    </div>
    """
  end
end
