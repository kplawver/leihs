steps_for(:work_days) do

  Given "$ip has default workdays" do 
  end

  Given "inventory_pool is open on $days" do |days|
    inventory_pool = Factory.create_inventory_pool
    inventory_pool.workday.monday = false
    inventory_pool.workday.tuesday = false
    inventory_pool.workday.wednesday = false
    inventory_pool.workday.thursday = false
    inventory_pool.workday.friday = false
    inventory_pool.workday.saturday = false
    inventory_pool.workday.sunday = false
    inventory_pool.workday.save
    days.split(",").each do |day|
      inventory_pool.workday.update_attributes(day.strip.downcase => true)
    end
  end
  
  Given "holidays are from $startdate - $finished because of $reason" do |startdate, finish, reason|
    ip = Factory.create_inventory_pool
    ip.holidays << Holiday.new(:start_date => Factory.parsedate(startdate),
                                :end_date => Factory.parsedate(finish),
                                :name => reason)
    ip.save                                            
  end
  
  Given "$date is free because of $reason" do |date, reason|
    ip = Factory.create_inventory_pool
    ip.holidays << Holiday.new(:start_date => Factory.parsedate(date),
                                :end_date => Factory.parsedate(date),
                                :name => reason)
    ip.save
  end
  
  Given "today is Sunday $date" do |date|
    @date = date
  end
  
	When "$who try to order an item for $date" do |who, date|
	  inventory_pool, inv_manager, user, model = Factory.create_dataset_simple

    # Login                            
    post "/session", :login => user.login
    @order.destroy if @order
    get '/user/order'
    @order = assigns(:order)
    
    post add_line_user_order_path( :model_id => model.id,
                              :quantity => 1,
                              :inventory_pool_id => inventory_pool.id,
                              :start_date => date,
                              :end_date => date)
                             
    @order = assigns(:order)
    @line = @order.order_lines.last
	end
	
	When "$who clicks '$action'" do |who, action|
	  @inventory_pool, inv_manager, @user, model = Factory.create_dataset_simple
	  
	  #Login as User
    post "/session", :login => inv_manager.login
    get backend_inventory_pool_hand_over_path(@inventory_pool) if action == 'hand over'
    get backend_inventory_pool_workdays_path(@inventory_pool) if action == 'Opening Times'

    @workday = assigns(:workday)
  end
	
	When "he tries to hand over an item to a customer" do
    get backend_inventory_pool_user_hand_over_path(@inventory_pool, @user)
    
    @contract = assigns(:contract)
    @contract.lines.size.should == 0
    
    post add_line_backend_inventory_pool_user_hand_over_path(@inventory_pool, @user, :model_id => Model.first.id, :quantity => 1)
                               
    @contract = assigns(:contract)
    @contract.lines.size.should == 1
    
  end

	
	Then "the order should not be approvable$reason" do |reason|
    @order.approvable?.should == false
  end
  
  Then "the order should be approvable$reason" do |reason|
    @order.approvable?.should == true
  end
	
	Then "that should be possible$reason" do
    @contract.lines.size.should == 1
    line = @contract.lines.first
    line.start_date = Factory.parsedate(@date)
    line.save.should == true
  end
  
  When "trying to set the end date to the same date" do  
    line = @contract.lines.first
    line.end_date = Factory.parsedate(@date)
    @save_successful = line.save
  end
  
	Then "that should not be possible $reason" do
	  @save_successful.should == false
  end

  Then "he sees that his inventory pool is currently open on $days" do |days|
    other_days = Workday::DAYS
    days.split(',').each do |day|
      other_days.delete(day.strip)
      @workday.send(day.strip).should == true
    end
    
    other_days.each do |day|
      if @workday.send(day) == true 
        puts "****************"
        puts @workday.inspect
        puts "****************"
      end
      @workday.send(day).should == false
    end
  end
  
  When "he deselects $days" do |days|
    days.split(',').each do |day|
      post close_backend_inventory_pool_workdays_path(@inventory_pool, :day => day.strip)
    end
  end
  
  When "he selects $days" do |days|
    days.split(',').each do |day|
      post open_backend_inventory_pool_workdays_path(@inventory_pool, :day => day.strip)
    end
  end
  
end