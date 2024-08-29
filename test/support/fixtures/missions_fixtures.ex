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
defmodule Resistance.MissionsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Resistance.Missions` context.
  """

  @doc """
  Generate a mission.
  """
  def mission_fixture(attrs \\ %{}) do
    {:ok, mission} =
      attrs
      |> Enum.into(%{

      })
      |> Resistance.Missions.create_mission()

    mission
  end

  @doc """
  Generate a mission_player.
  """
  def mission_player_fixture(attrs \\ %{}) do
    {:ok, mission_player} =
      attrs
      |> Enum.into(%{

      })
      |> Resistance.Missions.create_mission_player()

    mission_player
  end
end
