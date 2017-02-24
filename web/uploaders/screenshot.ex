defmodule Vutuv.Screenshot do
  use Arc.Definition

  # Include ecto support (requires package arc_ecto installed):
  use Arc.Ecto.Definition

  # To add a thumbnail version:
  @versions [:original, :thumb]

  # Whitelist file extensions:
  def validate({file, _}) do
    ~w(.jpg .png) |> Enum.member?(Path.extname(file.file_name))
  end

  # Define a thumbnail transformation:
  def transform(:thumb, _) do
    {:convert, "-strip -resize 200^x150 -gravity north -extent 200x150 -format png", :png}
  end

  # Use local storage
  def __storage, do: Arc.Storage.Local

  def storage_dir(_version, {_file, scope}) do
    "web/static/assets/images/screenshots/#{scope.id}"
  end

  # Override the persisted filenames:
  def filename(version, _) do
    version
  end
end
