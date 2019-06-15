defmodule Vutuv.Repo.Migrations.CreateTags do
  use Ecto.Migration

  def change do
    create table(:tags) do
      add :name, :string
      add :downcase_name, :string
      add :slug, :string
      add :description, :string
      add :url, :string

      timestamps()
    end
  end
end