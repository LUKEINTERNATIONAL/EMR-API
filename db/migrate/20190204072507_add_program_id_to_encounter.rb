class AddProgramIdToEncounter < ActiveRecord::Migration[5.2]
  def change
    add_column :encounter, :program_id, :integer, default: nil
  end
end
