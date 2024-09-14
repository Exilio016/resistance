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
defmodule ResistanceWeb.GameLive do
  alias Resistance.Missions
  alias Resistance.Games.Game
  alias Resistance.Users
  alias Phoenix.PubSub
  alias Resistance.Players
  alias Resistance.Games
  use ResistanceWeb, :live_view

  def mount(%{"id" => id}, _session, socket) do
    socket = assign(socket, vote_end: false, mission_end: false, mission_players: [])

    socket =
      try do
        game = Games.get_game!(id)
        PubSub.subscribe(Resistance.PubSub, "game-#{id}")
        user_id = socket.assigns.current_user.id

        is_reconnect = Enum.any?(game.players, fn %{user_id: id} -> id == user_id end)

        game_disconnected =
          if game.disconnected && game.user_id == user_id do
            false
          else
            game.disconnected
          end

        connected =
          if !is_reconnect && game.state == "Lobby" do
            if length(game.players) < 10 do
              Players.create_player(%{:user_id => user_id, :game_id => id, :ready => false})
              PubSub.broadcast(Resistance.PubSub, "game-#{id}", "game-update")
              PubSub.broadcast(Resistance.PubSub, "game-list", "game-update")
              true
            else
              false
            end
          else
            false
          end

        if !connected && !is_reconnect do
          push_navigate(socket, to: "/")
        else
          socket
          |> assign(disconnected: game_disconnected)
          |> assign(game: game)
        end
      rescue
        Ecto.NoResultsError ->
          socket
          |> put_flash(:error, "Game with id '#{id}' not found!")
          |> push_navigate(to: "/")
      end

    {:ok, socket}
  end

  def handle_info("game-update", socket) do
    id = socket.assigns.game.id
    user_id = socket.assigns.current_user.id

    socket =
      try do
        game = Games.get_game!(id)

        if game.user_id == user_id do
          Game.handle_game_state(game)
        end

        assign(socket, game: game)
      rescue
        Ecto.NoResultsError ->
          socket
          |> put_flash(:error, "Game with id '#{id}' not found!")
          |> push_navigate(to: "/")
      end

    {:noreply, socket}
  end

  def handle_info(%{id: "mission-end", mission_players: mission_players}, socket) do
    id = socket.assigns.game.id

    socket =
      try do
        game = Games.get_game!(id)
        result = length(Enum.filter(game.players, fn %{vote: vote} -> vote end))

        vote_result =
          if result > floor(length(game.players) / 2) do
            "The mission was succesful!"
          else
            "The mission failed!"
          end

        socket
        |> assign(game: game)
        |> assign(mission_end: true)
        |> assign(vote_result: vote_result)
        |> assign(mission_players: mission_players)
        |> push_event("show-modal", %{id: "mission-modal"})
      rescue
        Ecto.NoResultsError ->
          socket
          |> put_flash(:error, "Game with id '#{id}' not found!")
          |> push_navigate(to: "/")
      end

    {:noreply, socket}
  end

  def handle_info("vote-end", socket) do
    id = socket.assigns.game.id

    socket =
      try do
        game = Games.get_game!(id)
        result = length(Enum.filter(game.players, fn %{vote: vote} -> vote end))

        vote_result =
          if result > floor(length(game.players) / 2) do
            "Team approved!"
          else
            "Team rejected!"
          end

        socket
        |> assign(game: game)
        |> assign(vote_end: true)
        |> assign(vote_result: vote_result)
        |> push_event("show-modal", %{id: "vote-modal"})
      rescue
        Ecto.NoResultsError ->
          socket
          |> put_flash(:error, "Game with id '#{id}' not found!")
          |> push_navigate(to: "/")
      end

    {:noreply, socket}
  end

  def handle_info("disconnected", socket) do
    game = socket.assigns.game
    Games.delete_game(game)
    PubSub.broadcast(Resistance.PubSub, "game-#{game.id}", "game-update")
    PubSub.broadcast(Resistance.PubSub, "game-list", "game-update")
  end

  def terminate(_reason, socket) do
    game = socket.assigns.game
    user_id = socket.assigns.current_user.id

    if game.state == "Lobby" do
      for p <- game.players do
        if p.user_id == user_id do
          Players.delete_player(p)
        end
      end

      if game.user_id == user_id do
        Games.delete_game(game)
      end
    end

    if game.user_id == user_id do
      Games.update_game(game, %{disconnected: true})
      Process.send_after(self(), "disconnected", 5 * 60 * 1000)
    end

    PubSub.broadcast(Resistance.PubSub, "game-#{game.id}", "game-update")
    PubSub.broadcast(Resistance.PubSub, "game-list", "game-update")

    {:noreply, socket}
  end

  def get_current_player(game, user_id) do
    Enum.find(game.players, fn %{user_id: id} -> id == user_id end)
  end

  def is_user_selected(game, user_id) do
    selected = Players.get_all_selected(game)
    Enum.any?(selected, fn %{user_id: id} -> user_id == id end)
  end

  def need_to_show_spies(game, user_id) do
    player = get_current_player(game, user_id)

    case game.state do
      "Lobby" -> false
      "Defeat" -> true
      "Victory" -> true
      _ -> player.is_spy
    end
  end

  def handle_event("player-ready", _params, socket) do
    game = socket.assigns.game
    user_id = socket.assigns.current_user.id
    player = get_current_player(game, user_id)

    if player do
      Players.update_player(player, %{ready: true})
      PubSub.broadcast(Resistance.PubSub, "game-#{game.id}", "game-update")
    end

    {:noreply, socket}
  end

  def handle_event("team-selected", _params, socket) do
    game = socket.assigns.game
    user_id = socket.assigns.current_user.id
    player = get_current_player(game, user_id)
    selected = length(Players.get_all_selected(game))
    team_size = Game.get_team_size(game)

    if player do
      if selected == team_size do
        Players.update_player(player, %{ready: true})
        PubSub.broadcast(Resistance.PubSub, "game-#{game.id}", "game-update")
      end
    end

    {:noreply, socket}
  end

  def handle_event("player-vote", %{"vote" => vote}, socket) do
    game = socket.assigns.game
    user_id = socket.assigns.current_user.id
    player = get_current_player(game, user_id)

    if player do
      Players.update_player(player, %{ready: true, vote: vote == "true"})
      PubSub.broadcast(Resistance.PubSub, "game-#{game.id}", "game-update")
    end

    {:noreply, socket}
  end

  def handle_event("team-select", %{"id" => selected_id}, socket) do
    game = socket.assigns.game
    user_id = socket.assigns.current_user.id

    if game.state == "Team Selection" do
      leader = Enum.at(game.players, game.leader)

      if leader.user_id == user_id do
        selected_players = Players.get_all_selected(game)

        selected =
          Enum.find(game.players, fn %{id: id} -> String.to_integer(selected_id) == id end)

        if selected.selected do
          Players.update_player(selected, %{selected: false})
        else
          if length(selected_players) < Game.get_team_size(game) do
            Players.update_player(selected, %{selected: true})
          end
        end

        PubSub.broadcast(Resistance.PubSub, "game-#{game.id}", "game-update")
      end
    end

    {:noreply, socket}
  end

  def handle_event("close", _params, socket) do
    game = socket.assigns.game

    if game.user_id == socket.assigns.current_user.id do
      Games.delete_game(game)
    end

    {:noreply, push_navigate(socket, to: "/")}
  end

  def is_user_leader(game, user_id) do
    leader = Enum.at(game.players, game.leader)
    leader.user_id == user_id
  end

  def is_team_ready(game, user_id) do
    is_user_leader(game, user_id) and
      Game.get_team_size(game) == length(Players.get_all_selected(game))
  end

  def result_dialog(assigns) do
    ~H"""
    <dialog class="text-neutral-100 bg-neutral-900" id="vote-modal">
      <%= if @vote_end do %>
        <h2 class="text-xl text-center text-neutral-100"><%= @vote_result %></h2>
        <table class="min-w-full divide-y divide-neutral-700 text-neutral-100 overflow-y-scroll">
          <thead>
            <tr>
              <th scope="col" class="px-6 py-1 uppercase font-medium text-start text-neutral-500">
                Player
              </th>
              <th scope="col" class="px-6 py-1 uppercase font-medium text-end text-neutral-500">
                Vote
              </th>
            </tr>
          </thead>
          <tbody>
            <%= for player <- @game.players do %>
              <% user = Users.get_user!(player.user_id) %>
              <tr id={"vote-#{player.id}"} class="hover:bg-neutral-700">
                <td class="px-6 py-2 text-start"><%= user.email %></td>
                <td class="px-6 py-2 text-end">
                  <input type="checkbox" checked={player.vote} disabled />
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>
        <div class="flex relative justify-center mx-6 my-4">
          <button
            class="border border-transparent rounded-lg px-4 py-2 bg-emerald-900 hover:bg-emerald-700"
            phx-click={JS.dispatch("phx:close-modal", detail: %{id: "vote-modal"})}
          >
            Close
          </button>
        </div>
      <% end %>
    </dialog>
    """
  end

  def mission_dialog(assigns) do
    success = length(Enum.filter(assigns.mission_players, fn %{vote: vote} -> vote end))

    assigns =
      assign(assigns, %{success: success, failures: length(assigns.mission_players) - success})

    ~H"""
    <dialog class="text-neutral-100 bg-neutral-900" id="mission-modal">
      <%= if @mission_end do %>
        <h2 class="text-xl text-center text-neutral-100"><%= @vote_result %></h2>
        <div class="flex justify-between py-4">
          <span class="text-neutral-100">
            Success: <%= @success %>, Failures <%= @failures %>
          </span>
        </div>
        <table class="min-w-full divide-y divide-neutral-700 text-neutral-100 overflow-y-scroll">
          <thead>
            <tr>
              <th scope="col" class="px-6 py-1 uppercase font-medium text-start text-neutral-500">
                Player
              </th>
            </tr>
          </thead>
          <tbody>
            <%= for player <- @mission_players do %>
              <% user = Users.get_user!(player.user_id) %>
              <tr class="hover:bg-neutral-700">
                <td class="px-6 py-2 text-start"><%= user.email %></td>
              </tr>
            <% end %>
          </tbody>
        </table>
        <div class="flex relative justify-center mx-6 my-4">
          <button
            class="border border-transparent rounded-lg px-4 py-2 bg-emerald-900 hover:bg-emerald-700"
            phx-click={JS.dispatch("phx:close-modal", detail: %{id: "mission-modal"})}
          >
            Close
          </button>
        </div>
      <% end %>
    </dialog>
    """
  end

  def render(assigns) do
    success = Missions.get_mission_success_count(assigns.game)
    mission_count = Missions.get_mission_count(assigns.game)

    failures =
      mission_count - success -
        if assigns.game.state == "Mission" do
          1
        else
          0
        end

    assigns =
      assign(assigns, %{success: success, mission_count: mission_count, failures: failures})

    ~H"""
    <h2 class="text-xl text-center text-neutral-100"><%= @game.name %></h2>
    <%= if @game.state != "Lobby" do %>
      <h2 class="text-xl text-center text-neutral-100">
        Role: <%= if get_current_player(@game, @current_user.id).is_spy do
          "Spy"
        else
          "Resistance"
        end %>
      </h2>
      <div class="flex justify-between py-4">
        <span class="text-neutral-100">
          Mission #<%= @mission_count %>/5 - Success: <%= @success %>, Failures <%= @failures %>
        </span>
      </div>
    <% end %>
    <div class="flex justify-between py-4">
      <span class="text-neutral-100"><%= @game.state %></span>
      <%= case @game.state do %>
        <% "Lobby" -> %>
          <span class="text-neutral-100">Players <%= length(@game.players) %>/10</span>
        <% "Team Selection" -> %>
          <span class="text-neutral-100">
            Team selection failures: <%= @game.mission_sel_num %>
          </span>
          <span class="text-neutral-100">
            Players selected <%= length(Players.get_all_selected(@game)) %>/<%= Game.get_team_size(
              @game
            ) %>
          </span>
        <% "Team Vote" -> %>
          <span class="text-neutral-100">
            Players selected <%= length(Players.get_all_selected(@game)) %>/<%= Game.get_team_size(
              @game
            ) %>
          </span>
        <% "Mission" -> %>
          <span class="text-neutral-100">
            Players selected <%= length(Players.get_all_selected(@game)) %>/<%= Game.get_team_size(
              @game
            ) %>
          </span>
        <% "Defeat" -> %>
          <span class="text-neutral-100">
            The Spies won the game!
          </span>
        <% "Victory" -> %>
          <span class="text-neutral-100">
            The Resistance won the game!
          </span>
      <% end %>
    </div>
    <table class="min-w-full divide-y divide-neutral-700 text-neutral-100 overflow-y-scroll">
      <thead>
        <tr>
          <th scope="col" class="px-6 py-1 uppercase font-medium text-start text-neutral-500">
            Player
          </th>
          <%= case @game.state do %>
            <% "Lobby" -> %>
              <th scope="col" class="px-6 py-1 uppercase font-medium text-end text-neutral-500">
                Ready
              </th>
            <% "Team Selection" -> %>
              <th scope="col" class="px-6 py-1 uppercase font-medium text-end text-neutral-500">
                Selected
              </th>
            <% "Team Vote" -> %>
              <th scope="col" class="px-6 py-1 uppercase font-medium text-end text-neutral-500">
                Selected
              </th>
              <th scope="col" class="px-6 py-1 uppercase font-medium text-end text-neutral-500">
                Voted
              </th>
            <% "Mission" -> %>
              <th scope="col" class="px-6 py-1 uppercase font-medium text-end text-neutral-500">
                Selected
              </th>
            <% "Defeat" -> %>
            <% "Victory" -> %>
          <% end %>
          <%= if need_to_show_spies(@game, @current_user.id) do %>
            <th scope="col" class="px-6 py-1 uppercase font-medium text-end text-neutral-500">
              Spy
            </th>
          <% end %>
        </tr>
      </thead>
      <tbody>
        <%= for {player, index} <- Enum.with_index(@game.players) do %>
          <% user = Users.get_user!(player.user_id) %>
          <tr
            id={"player-#{player.id}"}
            class="hover:bg-neutral-700"
            phx-click="team-select"
            phx-value-id={player.id}
          >
            <td class="px-6 py-2 text-start">
              <%= user.email %><%= if @game.leader == index do
                " (leader)"
              end %>
            </td>
            <%= case @game.state do %>
              <% "Lobby" -> %>
                <td class="px-6 py-2 text-end">
                  <input type="checkbox" checked={player.ready} disabled />
                </td>
              <% "Team Selection" -> %>
                <td class="px-6 py-2 text-end">
                  <input type="checkbox" checked={player.selected} disabled />
                </td>
              <% "Team Vote" -> %>
                <td class="px-6 py-2 text-end">
                  <input type="checkbox" checked={player.selected} disabled />
                </td>
                <td class="px-6 py-2 text-end">
                  <input type="checkbox" checked={player.ready} disabled />
                </td>
              <% "Mission" -> %>
                <td class="px-6 py-2 text-end">
                  <input type="checkbox" checked={player.selected} disabled />
                </td>
              <% "Defeat" -> %>
              <% "Victory" -> %>
            <% end %>
            <%= if need_to_show_spies(@game, @current_user.id) do %>
              <td class="px-6 py-2 text-end">
                <input type="checkbox" checked={player.is_spy} disabled />
              </td>
            <% end %>
          </tr>
        <% end %>
      </tbody>
    </table>
    <div class="flex relative justify-between mx-6 my-4">
      <%= case @game.state do %>
        <% "Lobby" -> %>
          <button
            phx-click="player-ready"
            class="border border-transparent rounded-lg px-4 py-2 bg-emerald-900 hover:bg-emerald-700"
          >
            Ready
          </button>
        <% "Team Selection" -> %>
          <button
            phx-click="team-selected"
            class={"border border-transparent rounded-lg px-4 py-2 #{if is_team_ready(@game, @current_user.id) do "bg-emerald-900 hover:bg-emerald-700" else "bg-emerald-900" end}"}
            disabled={!is_team_ready(@game, @current_user.id)}
          >
            Select Team
          </button>
        <% "Team Vote" -> %>
          <button
            phx-click="player-vote"
            phx-value-vote="true"
            class="border border-transparent rounded-lg px-4 py-2 bg-emerald-900 hover:bg-emerald-700"
          >
            Approve team
          </button>
          <button
            phx-click="player-vote"
            phx-value-vote="false"
            class="border border-transparent rounded-lg px-4 py-2 bg-rose-900 hover:bg-rose-700"
          >
            Reject team
          </button>
        <% "Mission" -> %>
          <%= if is_user_selected(@game, @current_user.id) do %>
            <button
              phx-click="player-vote"
              phx-value-vote="true"
              class="border border-transparent rounded-lg px-4 py-2 bg-emerald-900 hover:bg-emerald-700"
            >
              Success
            </button>
            <button
              phx-click="player-vote"
              phx-value-vote="false"
              class="border border-transparent rounded-lg px-4 py-2 bg-rose-900 hover:bg-rose-700"
            >
              Failure
            </button>
          <% end %>
        <% "Defeat" -> %>
          <button
            phx-click="close"
            phx-value-vote="false"
            class="border border-transparent rounded-lg px-4 py-2 bg-rose-900 hover:bg-rose-700"
          >
            Close
          </button>
        <% "Victory" -> %>
          <button
            phx-click="close"
            phx-value-vote="false"
            class="border border-transparent rounded-lg px-4 py-2 bg-rose-900 hover:bg-rose-700"
          >
            Close
          </button>
      <% end %>
    </div>
    <%= result_dialog(assigns) %>
    <%= mission_dialog(assigns) %>
    """
  end
end
