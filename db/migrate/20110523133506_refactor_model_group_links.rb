class RefactorModelGroupLinks < ActiveRecord::Migration

  class ModelGroupsParent < ActiveRecord::Base
    belongs_to :model_group
    belongs_to :parent, :class_name => 'ModelGroup'  
  end

  def self.up
    # acts_as_dag
    create_table :model_group_links do |t|
      t.integer :ancestor_id
      t.integer :descendant_id
      t.boolean :direct
      t.integer :count
      t.string  :label
    end
    change_table    :model_group_links do |t|
      t.index       :ancestor_id
      t.index       :descendant_id
      t.index       :direct
    end    

    ModelGroupsParent.all.each do |mgp|
      ModelGroupLink.create_edge(mgp.parent, mgp.model_group)    
      mgp.model_group.set_label(mgp.parent, mgp.label) unless mgp.label.blank?
    end

    drop_table :model_groups_parents
  end

  def self.down
  end
end
