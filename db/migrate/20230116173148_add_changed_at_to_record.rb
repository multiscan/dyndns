class AddChangedAtToRecord < ActiveRecord::Migration[7.0]
  def change
    add_column :records, :changed_at, :datetime, default: 'CURRENT_TIMESTAMP'
  end
end
