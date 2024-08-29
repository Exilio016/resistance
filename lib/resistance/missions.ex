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
defmodule Resistance.Missions do
  @moduledoc """
  The Missions context.
  """

  import Ecto.Query, warn: false
  alias Resistance.Repo

  alias Resistance.Missions.Mission

  @doc """
  Returns the list of missions.

  ## Examples

      iex> list_missions()
      [%Mission{}, ...]

  """
  def list_missions do
    Repo.all(Mission)
  end

  @doc """
  Get the number of missions done on a Game
  """
  def get_mission_count(game) do
    from(m in Mission, where: m.game_id == ^game.id, select: count(m.id))
    |> Repo.one()
  end

  @doc """
  Get the current mission from the Game
  """
  def get_current_mission(game) do
    list =
      from(m in Mission, where: m.game_id == ^game.id, order_by: [desc: m.index])
      |> Repo.all()

    Enum.at(list, 0)
  end

  @doc """
  Get the number of missions that were successful in a Game
  """
  def get_mission_success_count(game) do
    from(m in Mission, where: m.game_id == ^game.id and m.success, select: count(m.id))
    |> Repo.one()
  end

  @doc """
  Gets a single mission.

  Raises `Ecto.NoResultsError` if the Mission does not exist.

  ## Examples

      iex> get_mission!(123)
      %Mission{}

      iex> get_mission!(456)
      ** (Ecto.NoResultsError)

  """
  def get_mission!(id), do: Repo.get!(Mission, id)

  @doc """
  Creates a mission.

  ## Examples

      iex> create_mission(%{field: value})
      {:ok, %Mission{}}

      iex> create_mission(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_mission(attrs \\ %{}) do
    %Mission{}
    |> Mission.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a mission.

  ## Examples

      iex> update_mission(mission, %{field: new_value})
      {:ok, %Mission{}}

      iex> update_mission(mission, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_mission(%Mission{} = mission, attrs) do
    mission
    |> Mission.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a mission.

  ## Examples

      iex> delete_mission(mission)
      {:ok, %Mission{}}

      iex> delete_mission(mission)
      {:error, %Ecto.Changeset{}}

  """
  def delete_mission(%Mission{} = mission) do
    Repo.delete(mission)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking mission changes.

  ## Examples

      iex> change_mission(mission)
      %Ecto.Changeset{data: %Mission{}}

  """
  def change_mission(%Mission{} = mission, attrs \\ %{}) do
    Mission.changeset(mission, attrs)
  end
end
