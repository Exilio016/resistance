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
defmodule Resistance.Repo.Migrations.CreateMissionPlayers do
  use Ecto.Migration

  def change do
    create table(:mission_players) do
      add :mission_id, references(:missions, on_delete: :delete_all), null: false
      add :player_id, references(:users, on_delete: :delete_all), null: false
      add :success, :boolean, null: false
      timestamps(type: :utc_datetime)
    end
  end
end
