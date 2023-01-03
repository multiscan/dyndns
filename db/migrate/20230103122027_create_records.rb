class CreateRecords < ActiveRecord::Migration[7.0]
  def change
    create_table :records do |t|
      t.string :name
      t.string :ip
      t.timestamps
    end
    add_index :records, :name, unique: true
  end
end
