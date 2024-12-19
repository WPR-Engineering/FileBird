class AddBackupPathToDownloaders < ActiveRecord::Migration[7.2]
  def change
    add_column :downloaders, :backup_path, :string
  end
end
