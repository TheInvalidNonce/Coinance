class CreateComments < ActiveRecord::Migration[5.1]
  def change
    create_table :comments do |t|
      t.string :note
      t.belongs_to :transaction

      t.timestamps
    end
  end
end