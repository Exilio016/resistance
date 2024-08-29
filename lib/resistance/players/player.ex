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
defmodule Resistance.Players.Player do
  use Ecto.Schema
  import Ecto.Changeset

  schema "players" do
    belongs_to :user, Resistance.Users.User
    belongs_to :game, Resistance.Games.Game
    field :ready, :boolean
    field :selected, :boolean
    field :is_spy, :boolean
    field :vote, :boolean
    field :order, :integer

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(player, attrs) do
    player
    |> cast(attrs, [:user_id, :game_id, :ready, :selected, :is_spy, :vote, :order])
    |> validate_required([:user_id, :game_id, :ready])
    |> unique_constraint([:user_id, :game_id])
  end
end
