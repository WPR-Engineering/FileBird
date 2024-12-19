class AddTempDlPathToSettings < ActiveRecord::Migration[7.2]
  def change
    add_column :settings, :temporary_download_path, :string
  end
end
