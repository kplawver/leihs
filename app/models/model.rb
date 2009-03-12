class Model < ActiveRecord::Base
  has_many :items # TODO filter children items, has_many :all_items ??
  has_many :locations, :through => :items, :uniq => true  # OPTIMIZE N+1 select problem, :include => :inventory_pools
  has_many :inventory_pools, :through => :locations, :uniq => true
  
  has_many :order_lines
  has_many :contract_lines
  has_many :properties
  has_many :accessories
  has_many :images

  # ModelGroups
  has_many :model_links
  has_many :model_groups, :through => :model_links, :uniq => true
  has_many :categories, :through => :model_links, :source => :model_group, :conditions => {:type => 'Category'}
  has_many :templates, :through => :model_links, :source => :model_group, :conditions => {:type => 'Template'}
  
  # Packages
  has_many :package_items, :through => :items, :source => :children
                
########
  has_and_belongs_to_many :compatibles,
                          :class_name => "Model",
                          :join_table => "models_compatibles",
                          :foreign_key => "model_id",
                          :association_foreign_key => "compatible_id",
                     #TODO :insert_sql => "INSERT INTO models_compatibles (model_id, compatible_id)
                     #                 VALUES (#{id}, #{record.id}), (#{record.id}, #{id})" 
                          :after_add => :add_bidirectional_compatibility,
                          :after_remove => :remove_bidirectional_compatibility
  def add_bidirectional_compatibility(compatible)
    compatible.compatibles << self unless compatible.compatibles.include?(self)
  end
  
  def remove_bidirectional_compatibility(compatible)
    compatible.compatibles.delete(self) if compatible.compatibles.include?(self) #old# rescue nil
  end
########

  named_scope :without_items, :select => "models.*",
                              :joins => "LEFT JOIN items ON items.model_id = models.id",
                              :conditions => ['items.model_id IS NULL']

  named_scope :packages, :conditions => { :is_package => true }
  
#############################################  

  validates_uniqueness_of :name
  #validates_length_of :name, :minimum => 1 #, :too_short => "please enter at least %d character", :if => Proc.new {|i| i.step == :step_item}
  validates_presence_of :name #, :if => Proc.new {|i| i.step == :step_item}

  acts_as_ferret :fields => [ :name, :manufacturer, :category_names, :properties_values, :items_inventory_codes ], :store_class_name => true, :remote => true

#############################################  

  def to_s
    "#{name}"
  end

  # compares two objects in order to sort them
  def <=>(other)
    self.name <=> other.name
  end

  # TODO 06** define main image
  def image_thumb
    ( images.empty? ? nil : images.first.public_filename(:thumb) )
  end

  def lines
    order_lines + contract_lines
  end
  
#############################################  
# Availability
#############################################  

  def available_periods_for_document_line(document_line, current_time = Date.today)
    create_availability(current_time, document_line, document_line.inventory_pool, document_line.document.user).periods
  end

  # TODO *e* inventory_pools array ??
  def available_periods_for_inventory_pool(inventory_pool, user, current_time = Date.today)
    create_availability(current_time, nil, inventory_pool, user).periods
  end

  def available_dates_for_document_line(start_date, end_date, document_line, current_time = Date.today)
    create_availability(current_time, document_line, document_line.inventory_pool, document_line.document.user).dates(start_date, end_date)
  end

  def available_dates_for_inventory_pool(start_date, end_date, inventory_pool, user, current_time = Date.today)
    create_availability(current_time, nil, inventory_pool, user).dates(start_date, end_date)
  end  
  
  # TODO *e* maximum_available_for_document_line method ??
  def maximum_available_for_inventory_pool(date, inventory_pool, user, current_time = Date.today)
    create_availability(current_time, nil, inventory_pool, user).period_for(date).quantity
  end
  
  def maximum_available_in_period_for_document_line(start_date, end_date, document_line, current_time = Date.today)
    if (start_date.nil? && end_date.nil?)
      return items.size
    else
      create_availability(current_time, document_line, document_line.inventory_pool, document_line.document.user).maximum_available_in_period(start_date, end_date)
    end
  end  

  def maximum_available_in_period_for_inventory_pool(start_date, end_date, inventory_pool, user, current_time = Date.today)
    if (start_date.nil? && end_date.nil?)
      return items.size
    else
      create_availability(current_time, nil, inventory_pool, user).maximum_available_in_period(start_date, end_date)
    end
  end  

#############################################  

  # TODO 04** model chart
  def chart(*args)
    chart_google(*args)
#    chart_gruff(*args)
  end

#old#
  def chart_google(user, inventory_pool = nil, days_from_today = 0, days_from_start = 90)
    inventory_pool ||= (user.inventory_pools & self.inventory_pools).first # TODO 17** collect all available inventory_pools
    days_from_today ||= 0 # OPTIMIZE
    days_from_start ||= 90 # OPTIMIZE
    start_date = Date.today + days_from_today.to_i.days
    end_date = start_date + days_from_start.to_i.days
    
    availabilities = available_dates_for_inventory_pool(start_date, end_date, inventory_pool, user)
    values = []
    days = []
    months = []
    last_value = nil
    last_month = nil
    availabilities.each do |a|
      values << a[1]
      days << (last_value != a[1] ? a[0].day : nil)
      months << (last_month != a[0].month ? a[0].strftime('%b') : nil)      
      last_value = a[1] 
      last_month = a[0].month
    end

    values_uniq = values.uniq
    values_max = values.max

    x1_labels = days.join('|')
    x2_labels = months.join('|')
#    y_labels = (0..values_max).to_a.collect{|v| values.include?(v) ? v : nil}.join('|')
    y_labels = values_uniq.join('|')
    y_positions = values_uniq.join(',')

    args = []
    args << "cht=bvs"
    args << "chs=800x150"
    args << "chxt=x,x,y,r"
    args << "chxtc=0,-200|1,5|2,-800"
    args << "chxs=1,000000,12,-1,lt,000000"
    args << "chxl=0:|#{x1_labels}|1:|#{x2_labels}|2:|#{y_labels}|3:|#{y_labels}"
    args << "chd=t:#{values.join(',')}"
    args << "chbh=7,1"
    args << "chds=0,#{values_max}"
    args << "chxr=2,0,#{values_max}|3,0,#{values_max}"
    args << "chxp=2,#{y_positions}|3,#{y_positions}"
    
    return "http://chart.apis.google.com/chart?#{args.join('&')}" 
  end

# TODO
#new#
  def chart_gruff(user, inventory_pool = nil, days_from_today = 0, days_from_start = 90)
#### start copy-paste    
    inventory_pool ||= (user.inventory_pools & self.inventory_pools).first # TODO 17** collect all available inventory_pools
    days_from_today ||= 0 # OPTIMIZE
    days_from_start ||= 90 # OPTIMIZE
    start_date = Date.today + days_from_today.to_i.days
    end_date = start_date + days_from_start.to_i.days
    
    availabilities = available_dates_for_inventory_pool(start_date, end_date, inventory_pool, user)
    values = []
    days = []
    months = []
    last_value = nil
    last_month = nil
    availabilities.each do |a|
      values << a[1]
      days << (last_value != a[1] ? a[0].day : nil)
      months << (last_month != a[0].month ? a[0].strftime('%b') : nil)      
      last_value = a[1] 
      last_month = a[0].month
    end
#### end copy-paste
    
    require 'rubygems'
    require 'gruff'
    
    g = Gruff::Bar.new("800x150")
    g.font = '/Library/Fonts/Arial.ttf' # TODO define local fonts
    g.title_font_size = g.marker_font_size = g.legend_font_size = 12
    g.hide_legend = true
    g.top_margin = -30
    g.right_margin = 5
#    g.bottom_margin = -10
    g.left_margin = -5
    g.data("Items", values)
#    g.data("Oranges", [4, 8, 7, 9, 8, 9])
#    g.data("Watermelon", [2, 3, 1, 5, 6, 8])
#    g.data("Peaches", [9, 9, 10, 8, 7, 9])
    
    g.labels = {0 => 'Jan', 20 => 'Feb', 30 => 'Mar'}
    g.minimum_value = 1
    
    g.theme_37signals
    
    return g    
  end

#############################################  

  def add_to_document(document, user_id, quantity = nil, start_date = nil, end_date = nil, inventory_pool = nil)
    document.add_line(quantity, self, user_id, start_date, end_date, inventory_pool)
  end  

  private
  
  def create_availability(current_time, document_line, inventory_pool, user)
    i = self.items.borrowable.all(:joins => :location,
                                  :conditions => ['required_level <= ? AND locations.inventory_pool_id = ?',
                                                  (user.nil? ? 1 : user.level_for(inventory_pool)), inventory_pool.id])    
                             
    r = DocumentLine.current_and_future_reservations(id, inventory_pool, document_line, current_time)
    
    a = Availability.new(i.size, Date.today, nil, current_time)
    a.model = self
    a.reservations(r)
    a
  end
  
  def category_names
    categories.collect(&:name).uniq.join(" ")
  end

  def properties_values
    properties.collect(&:value).uniq.join(" ")
  end
  
  def items_inventory_codes
    items.collect(&:inventory_code).join(" ")
  end

end
