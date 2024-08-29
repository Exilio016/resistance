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
defmodule Resistance.MissionsTest do
  use Resistance.DataCase

  alias Resistance.Missions

  describe "missions" do
    alias Resistance.Missions.Mission

    import Resistance.MissionsFixtures

    @invalid_attrs %{}

    test "list_missions/0 returns all missions" do
      mission = mission_fixture()
      assert Missions.list_missions() == [mission]
    end

    test "get_mission!/1 returns the mission with given id" do
      mission = mission_fixture()
      assert Missions.get_mission!(mission.id) == mission
    end

    test "create_mission/1 with valid data creates a mission" do
      valid_attrs = %{}

      assert {:ok, %Mission{} = mission} = Missions.create_mission(valid_attrs)
    end

    test "create_mission/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Missions.create_mission(@invalid_attrs)
    end

    test "update_mission/2 with valid data updates the mission" do
      mission = mission_fixture()
      update_attrs = %{}

      assert {:ok, %Mission{} = mission} = Missions.update_mission(mission, update_attrs)
    end

    test "update_mission/2 with invalid data returns error changeset" do
      mission = mission_fixture()
      assert {:error, %Ecto.Changeset{}} = Missions.update_mission(mission, @invalid_attrs)
      assert mission == Missions.get_mission!(mission.id)
    end

    test "delete_mission/1 deletes the mission" do
      mission = mission_fixture()
      assert {:ok, %Mission{}} = Missions.delete_mission(mission)
      assert_raise Ecto.NoResultsError, fn -> Missions.get_mission!(mission.id) end
    end

    test "change_mission/1 returns a mission changeset" do
      mission = mission_fixture()
      assert %Ecto.Changeset{} = Missions.change_mission(mission)
    end
  end

  describe "mission_players" do
    alias Resistance.Missions.MissionPlayer

    import Resistance.MissionsFixtures

    @invalid_attrs %{}

    test "list_mission_players/0 returns all mission_players" do
      mission_player = mission_player_fixture()
      assert Missions.list_mission_players() == [mission_player]
    end

    test "get_mission_player!/1 returns the mission_player with given id" do
      mission_player = mission_player_fixture()
      assert Missions.get_mission_player!(mission_player.id) == mission_player
    end

    test "create_mission_player/1 with valid data creates a mission_player" do
      valid_attrs = %{}

      assert {:ok, %MissionPlayer{} = mission_player} = Missions.create_mission_player(valid_attrs)
    end

    test "create_mission_player/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Missions.create_mission_player(@invalid_attrs)
    end

    test "update_mission_player/2 with valid data updates the mission_player" do
      mission_player = mission_player_fixture()
      update_attrs = %{}

      assert {:ok, %MissionPlayer{} = mission_player} = Missions.update_mission_player(mission_player, update_attrs)
    end

    test "update_mission_player/2 with invalid data returns error changeset" do
      mission_player = mission_player_fixture()
      assert {:error, %Ecto.Changeset{}} = Missions.update_mission_player(mission_player, @invalid_attrs)
      assert mission_player == Missions.get_mission_player!(mission_player.id)
    end

    test "delete_mission_player/1 deletes the mission_player" do
      mission_player = mission_player_fixture()
      assert {:ok, %MissionPlayer{}} = Missions.delete_mission_player(mission_player)
      assert_raise Ecto.NoResultsError, fn -> Missions.get_mission_player!(mission_player.id) end
    end

    test "change_mission_player/1 returns a mission_player changeset" do
      mission_player = mission_player_fixture()
      assert %Ecto.Changeset{} = Missions.change_mission_player(mission_player)
    end
  end
end
