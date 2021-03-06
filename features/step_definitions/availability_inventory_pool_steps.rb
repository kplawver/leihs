Given "this model has $number item$s in inventory pool $ip" do |number, s, ip|
  inventory_pool = InventoryPool.find_by_name(ip)
  number.to_i.times do | i |
    Factory.create_item(:model => @model, :inventory_pool => inventory_pool)
  end
  inventory_pool.items.count(:conditions => {:model_id => @model.id}).should == number.to_i
end

Then "the maximum number of available '$model' for '$who' is $size" do |model, who, size|
  user = User.find_by_login(who)
  @model = Model.find_by_name(model)
  user.items.count(:conditions => {:model_id => @model.id}).should == size.to_i
end

###########################################################################

Then /it asks for ([0-9]+) item(s?)$/ do |number, s|
  total = 0
  @orders.each do |o|
    total += o.lines.collect(&:quantity).sum
  end
  total.should == number.to_i
end

###########################################################################

Then "he gets an empty result set" do
  @models.empty?.should == true
end

Then "he sees the '$model' model" do |model|
  m = Model.find_by_name(model)
  @models.include?(m).should == true
end

Then "all order lines should be available" do
  @order.order_lines.all?{|l| l.available? }.should be_true
end

Then "some order lines should not be available" do
 @order.order_lines.any?{|l| not l.available? }.should be_true
end
