class AddTtlAndTypeToRecord < ActiveRecord::Migration[7.0]
  def change
    add_column :records, :ttl, :integer, default: 600
    add_column :records, :kind, :string, default: "A"
  end
end
