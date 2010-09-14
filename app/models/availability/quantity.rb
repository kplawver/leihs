module Availability
  class Quantity < ActiveRecord::Base
    set_table_name "availability_quantities"

    belongs_to :change
    belongs_to :group
  
    validates_presence_of :change_id
#tmp#2    validates_presence_of :group_id
    validates_presence_of :in_quantity
    validates_presence_of :out_quantity
    
    validates_uniqueness_of :group_id, :scope => :change_id
  
    has_many :out_document_lines, :dependent => :destroy, :class_name => "Availability::OutDocumentLine"
    #TODO# has_many :document_lines, :through => :out_document_lines

    def to_out(document_line)
      decrement(:in_quantity, document_line.quantity)
      increment(:out_quantity, document_line.quantity)
      out_document_lines.create(:document_line => document_line)
      self
    end

    #tmp#6 TODO really needed ??
    def to_in(document_line)
      increment(:in_quantity, document_line.quantity)
      decrement(:out_quantity, document_line.quantity)
      odl = out_document_lines.scoped_by_document_line_type_and_document_line_id(document_line.class.class_name, document_line.id).first
      out_document_lines.delete(odl)
      self
    end
    
  end

####################################

  class OutDocumentLine < ActiveRecord::Base
    set_table_name "availability_out_document_lines"

    belongs_to :quantity
    belongs_to :document_line, :polymorphic => true

    validates_uniqueness_of :quantity_id, :scope => [:document_line_type, :document_line_id]
  end

end