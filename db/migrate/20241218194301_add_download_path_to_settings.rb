class AddDownloadPathToSettings < ActiveRecord::Migration[7.2]
  def change
    add_column :settings, :download_path, :string
  end
end
