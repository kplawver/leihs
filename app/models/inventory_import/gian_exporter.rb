class InventoryImport::GianExporter
  
  def start(pool = nil)
    connect_prod

    export_items(pool)
  end

  def export_items(pool)
    #puts "Exporting #{pool}"
    items = Item.all(:conditions => {:inventory_pool_id => InventoryPool.find_by_name(pool).id})
    puts "create table imported_ids(id int);"
    
    items.each do |i| 
      old_id = i.inventory_code[3..i.inventory_code.length]
      gegenstand = InventoryImport::Gegenstand.first(:conditions => {:id => old_id })
      if gegenstand
      #  puts "# Ignoring " + gegenstand.id.to_s
      else
        #puts "Importing " + old_id
        s = "insert into gegenstands(id, modellbezeichnung, hersteller, info_url, inventar_abteilung, herausgabe_abteilung, seriennr, letzte_pruefung, ausmusterdatum, ausmustergrund)"
        s = s + " VALUES (#{old_id}, '#{i.model.name}', '#{i.model.manufacturer}', '#{i.model.info_url}', 'SFV', 'SFV','#{i.serial_number}', '#{i.last_check}', '#{i.retired}', '#{i.retired_reason}');"
        puts s
        puts "INSERT INTO imported_ids(id) VALUES(#{old_id});"
#        attributes = {
#            :id => old_id,
#            :modellbezeichnung => i.model.name,
#            :hersteller => i.model.manufacturer,
#            :info_url => i.model.info_url,
#            :inventar_abteilung => pool, #i.inventory_code[0..3], 
#            :seriennr => i.serial_number,
#            :letzte_pruefung => i.last_check,
#            :ausmusterdatum => i.retired,
#            :ausmustergrund => i.retired_reason
#          }
#        i = InventoryImport::Gegenstand.create(attributes)
#        if i.errors.size > 0
#          puts "Fehler: "
#          puts i.errors.inspect
#        end
      end
    end

    puts "select 'unsuccessfully imported: ',  id from imported_ids where id not in (select id from gegenstands);"
    
  end
  
  def import_items(pool)
    condition = "original_id is null"
    condition += " and herausgabe_abteilung = '#{pool}'" if pool
    puts "Only importing inventory pool #{pool}" if pool
    inventar = InventoryImport::Gegenstand.find(:all, :conditions => condition)
    count = 0
    successfull = 0
    
    inventar.each do |gegenstand|

      location = get_location(gegenstand)

      cat_name = gegenstand.paket.art if gegenstand.paket
      cat_name ||= gegenstand.art
      
      if cat_name.blank?
        puts "Assigning '#{gegenstand.modellbezeichnung}' to anonymous category because it belongs to empty category."
  cat_name = "Andere Hardware" 
      end

        if location.nil? 
          puts "Ignoring #{gegenstand.id} - '#{gegenstand.modellbezeichnung}' because no inventorypool was found."
        else
         # puts "Found: #{item.Inv_Serienr} - #{item.Art_Bezeichnung} = #{gegenstand.modellbezeichnung}"
          attributes = {
          }
          model = Model.find_or_create_by_name attributes
          model.update_attributes(attributes)
          
          add_picture(model, gegenstand.bild_url) if gegenstand.bild_url and not gegenstand.bild_url.blank? and model.images.size == 0

          cat_name ||= "Andere Hardware"
          category = Category.find(:first, :conditions => ['name = ?', cat_name])
          if category.nil?
            if model.categories.count == 0
              category = Category.create(:name => cat_name)
            end
          end
          category.models << model unless category.nil? or category.models.include?(model) # OPTIMIZE 13** avoid condition, check uniqueness on ModelLink          
      
          if location.nil?
            puts "Ignoring item with id: #{gegenstand.id} because I couldn't figure out to which inventory pool it belongs."
          else
            item_attributes = {
              :inventory_code => (gegenstand.inventar_abteilung.upcase + gegenstand.id.to_s),
              :serial_number => gegenstand.seriennr,
              :model => model,
              :inventory_pool => get_owner(gegenstand.inventar_abteilung),
              :owner => get_owner(gegenstand.inventar_abteilung),
              :last_check => gegenstand.letzte_pruefung,
              :required_level => (gegenstand.paket and gegenstand.paket.ausleihbefugnis > 1) ? AccessRight::EMPLOYEE : AccessRight::CUSTOMER,
              :retired => gegenstand.ausmusterdatum,
              :retired_reason => gegenstand.ausmustergrund,
              :invoice_number => gegenstand.kaufvorgang.nil? ? '' : gegenstand.kaufvorgang.rechnungsnr,
              :invoice_date => gegenstand.kaufvorgang.nil? ? nil : gegenstand.kaufvorgang.kaufdatum,
              :is_incomplete => gegenstand.paket.nil? ? false : (gegenstand.paket.status == 0),
              :is_broken => gegenstand.paket.nil? ? false : (gegenstand.paket.status == -2),
              :price => (gegenstand.kaufvorgang.nil? or gegenstand.kaufvorgang.kaufpreis.nil?) ? 0 : gegenstand.kaufvorgang.kaufpreis / 100
            }
 
            item = Item.find_or_create_by_inventory_code item_attributes[:inventory_code]
            item.is_borrowable = gegenstand.ausleihbar? if item.id == 0
            item.update_attributes(item_attributes)
            
            puts "Errors: '#{item_attributes[:inventory_code]}' - #{item.inventory_code}  #{item.id} #{item.errors.full_messages}" if item.errors.size > 0
            successfull += 1
          end
          count += 1
        end
    end
    puts "--------------"
    puts "Total: #{count}"
    puts "Successfull: #{successfull}"
    puts "Not so successfull: #{count - successfull}"
    
  end
  
  def get_location(gegenstand)
    if gegenstand.paket
      o = get_owner(gegenstand.paket.geraetepark.name)
    else
      o = get_owner(gegenstand.inventar_abteilung)
      if o.nil?
        puts "--> Also no owner found..."
      end
    end
    o
  end
  
  def get_owner(inv_abt)
    o = InventoryPool.find(:first, :conditions => ['name = ?', inv_abt])
    o = InventoryPool.find(:first, :conditions => ['name = ?', use_new_name_for(inv_abt)]) unless o
    puts "#{inv_abt} not found." if o.nil?
    o
  rescue
    puts "InventoryPool '#{inv_abt}' not found."
    nil
  end
  
  def use_new_name_for(inv_abt)
    return "VMK" if inv_abt.upcase == "SNM" 
    return "VMK" if inv_abt.upcase == "VNM"
    return "VIAD" if inv_abt.upcase == "IAD"
    inv_abt
  end

  def add_picture(model, url)
    url = url.gsub("hgkz", "zhdk")
    url = URI.parse(url)
    h = Net::HTTP.new(url.host, 80)

    resp, data = h.get(url.path, nil)
    if resp.message == "OK"
      
      File.open("picture.jpg", "w") { |f| f.write(data) }
      image = Image.new(:temp_path => "picture.jpg", :filename => 'picture.jpg', :content_type => 'image/jpg')
      image.model = model
      if not image.save
        puts "Couldn't create file: #{url} for #{model.name}"
      end
    else
      puts "Couldn't download: #{url} (for #{model.name})"
    end
  rescue
    puts "Couldn't append #{url} to #{model.name}"
  end


    def connect_dev
      InventoryImport::Kaufvorgang.establish_connection(leihs_dev)
      InventoryImport::Geraetepark.establish_connection(leihs_dev)
      InventoryImport::Gegenstand.establish_connection(leihs_dev)
      InventoryImport::Paket.establish_connection(leihs_dev)
      InventoryImport::User.establish_connection(leihs_dev)
      InventoryImport::GeraeteparksUser.establish_connection(leihs_dev)
      InventoryImport::ItHelp.establish_connection(it_help_dev)
    end

    def it_help_dev
      {   :adapter => 'mysql',
          :host => '127.0.0.1',
          :database => 'ithelp_development',
          :encoding => 'latin1',
          :username => 'root',
          :password => '' }
    end

    def leihs_dev
      {   :adapter => 'mysql',
          :host => '127.0.0.1',
          :database => 'rails_leihs_dev',
          :encoding => 'utf8',
          :username => 'root',
          :password => '' }
    end

    def connect_prod
      
        InventoryImport::Kaufvorgang.establish_connection(leihs_prod)
        InventoryImport::Geraetepark.establish_connection(leihs_prod)
        InventoryImport::Gegenstand.establish_connection(leihs_prod)
        InventoryImport::Paket.establish_connection(leihs_prod)
        InventoryImport::User.establish_connection(leihs_prod)
        InventoryImport::GeraeteparksUser.establish_connection(leihs_prod)
        InventoryImport::ItHelp.establish_connection(it_help_prod)
    end
    
    def it_help_prod
        { :adapter => 'mysql',
          :host => '195.176.254.49',
          :database => 'ithelp_alt',
          :encoding => 'utf8',
          :username => 'helpread',
          :password => '2read.0nly!' }
    end
    
    def leihs_prod
       {  :adapter => 'mysql',
          :host => '195.176.254.49',
          :database => 'rails_leihs',
          :encoding => 'utf8',
          :username => 'leihsread',
          :password => '2read.0nly!' }
    end

end