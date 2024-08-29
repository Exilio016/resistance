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
defmodule ResistanceWeb.GameCreateLive do 
  alias Phoenix.PubSub
  alias Resistance.Games
  alias Resistance.Games.Game
  use ResistanceWeb, :live_view

  def mount(_params, _session, socket) do 
    socket = assign(socket, form: to_form(Games.change_game(%Game{})))
    {:ok, socket}
  end

  def render(assigns) do 
    ~H"""
      <h2 class="text-xl text-center text-neutral-100"> Create Game</h2>
      <.form for={@form} phx-submit="save">
        <.input class="text-neutral-100" field={@form[:name]} placeholder="Name..."/>
        <div class="flex justify-center my-4">
          <input class="text-neutral-100 bg-emerald-900 hover:bg-emerald-700 rounded-lg px-6 py-2" type="submit" value="Create" >
        </div>
      </.form>
    """
  end

  def handle_event("save", %{"game" => game}, socket) do 
    current_user = socket.assigns.current_user
    result = Games.create_game(current_user, Map.put(game, "state", "Lobby")) 
    case result do 
      {:ok, game} -> 
        PubSub.broadcast(Resistance.PubSub, "game-list", "game-update")
        {:noreply, push_navigate(socket, to: "/game/#{game.id}")}
      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset)) }
    end
  end

end
