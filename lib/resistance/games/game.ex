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
defmodule Resistance.Games.Game do
  alias Phoenix.PubSub
  alias Resistance.Missions
  alias Resistance.Games
  alias Resistance.Players
  use Ecto.Schema
  import Ecto.Changeset

  schema "games" do
    field :name, :string
    belongs_to :user, Resistance.Users.User
    has_many :players, Resistance.Players.Player
    has_many :missions, Resistance.Missions.Mission
    field :state, :string
    field :leader, :integer
    field :mission_sel_num, :integer
    field :disconnected, :boolean

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(game, attrs) do
    game
    |> cast(attrs, [:name, :user_id, :state, :leader, :mission_sel_num, :disconnected])
    |> validate_required([:name, :user_id, :state])
  end

  def is_all_players_ready(players) do
    Enum.all?(players, fn %{ready: ready} -> ready == true end)
  end

  def select_spies(game, ammount) do
    :rand.seed(:exsss, System.system_time(:second) + 313)
    spies = Enum.take(Enum.shuffle(game.players), ammount)

    for spy <- spies do
      Players.update_player(spy, %{is_spy: true})
    end

    :ok
  end

  def select_spies(game) do
    len = length(game.players)

    case len do
      5 -> select_spies(game, 2)
      6 -> select_spies(game, 2)
      7 -> select_spies(game, 3)
      8 -> select_spies(game, 3)
      9 -> select_spies(game, 3)
      10 -> select_spies(game, 4)
    end

    :ok
  end

  def get_team_size(game) do
    len = length(game.players)

    mission_num =
      if game.state == "Mission" do
        Missions.get_mission_count(game) - 1
      else
        Missions.get_mission_count(game)
      end

    cond do
      len == 5 ->
        cond do
          mission_num == 0 or mission_num == 2 -> 2
          true -> 3
        end

      len == 6 ->
        cond do
          mission_num == 0 -> 2
          mission_num == 1 or mission_num == 3 -> 3
          true -> 4
        end

      len == 7 ->
        cond do
          mission_num == 0 -> 2
          mission_num < 3 -> 3
          true -> 4
        end

      true ->
        cond do
          mission_num == 0 -> 3
          mission_num < 3 -> 4
          true -> 5
        end
    end
  end

  def shuffle_players(players) do
    :rand.seed(:exsss, System.system_time(:second))
    players = Enum.with_index(Enum.shuffle(players))

    for {p, index} <- players do
      Players.update_player(p, %{order: index})
    end

    players
  end

  def start_game(game) do
    {leader, index} = Enum.random(shuffle_players(game.players))
    select_spies(game)
    Players.update_player(leader, %{ready: false})
    Games.update_game(game, %{state: "Team Selection", leader: index, mission_sel_num: 0})

    PubSub.broadcast(Resistance.PubSub, "game-#{game.id}", "game-update")
    PubSub.broadcast(Resistance.PubSub, "game-list", "game-update")
  end

  def start_vote(game) do
    Games.update_game(game, %{state: "Team Vote"})

    for p <- game.players do
      Players.update_player(p, %{ready: false})
    end

    PubSub.broadcast(Resistance.PubSub, "game-#{game.id}", "game-update")
  end

  def end_vote(game) do
    approved = length(Enum.filter(game.players, fn %{vote: vote} -> vote end))
    index = Missions.get_mission_count(game)

    if(approved > floor(length(game.players) / 2)) do
      Games.update_game(game, %{state: "Mission", mission_sel_num: 0})
      Missions.create_mission(%{game_id: game.id, index: index})

      for p <- Players.get_all_selected(game) do
        Players.update_player(p, %{ready: false})
      end
    else
      leader = rem(game.leader + 1, length(game.players))
      mission_sel_num = game.mission_sel_num + 1

      if mission_sel_num < 5 do
        Games.update_game(game, %{
          state: "Team Selection",
          mission_sel_num: mission_sel_num,
          leader: leader
        })

        p_leader = Enum.at(game.players, leader)

        for p <- game.players do
          Players.update_player(p, %{ready: p.id != p_leader.id, selected: false})
        end
      else
        Games.update_game(game, %{
          state: "Defeat"
        })
      end
    end

    PubSub.broadcast(Resistance.PubSub, "game-#{game.id}", "vote-end")
  end

  def end_mission(game) do
    players = Players.get_all_selected(game)
    failures = length(Enum.filter(players, fn %{vote: vote} -> !vote end))
    mission = Missions.get_current_mission(game)

    result =
      if length(game.players) > 6 and mission.index == 3 do
        if failures > 1 do
          false
        else
          true
        end
      else
        if failures > 0 do
          false
        else
          true
        end
      end

    Missions.update_mission(mission, %{success: result})

    count = Missions.get_mission_count(game)
    success = Missions.get_mission_success_count(game)

    state =
      cond do
        success == 3 -> "Victory"
        count - success == 3 -> "Defeat"
        true -> "Team Selection"
      end

    leader = rem(game.leader + 1, length(game.players))
    Games.update_game(game, %{state: state, leader: leader, mission_sel_num: 0})
    leader_id = Enum.at(game.players, leader).id

    for p <- game.players do
      Players.update_player(p, %{ready: p.id != leader_id, selected: false})
    end

    PubSub.broadcast(Resistance.PubSub, "game-#{game.id}", %{
      id: "mission-end",
      mission_players: players,
      mission_result: result
    })
  end

  def handle_game_state(game) do
    len = length(game.players)

    if is_all_players_ready(game.players) do
      case game.state do
        "Lobby" ->
          if len >= 5 do
            start_game(game)
          end

        "Team Selection" ->
          start_vote(game)

        "Team Vote" ->
          end_vote(game)

        "Mission" ->
          end_mission(game)
      end
    end
  end
end
