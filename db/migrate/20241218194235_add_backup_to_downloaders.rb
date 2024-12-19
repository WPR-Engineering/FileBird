class AddBackupToDownloaders < ActiveRecord::Migration[7.2]
  def change
    add_column :downloaders, :backup, :boolean
  end
end
