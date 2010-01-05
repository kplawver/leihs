require 'net/ldap'
    
class Authenticator::LdapAuthenticationController < Authenticator::AuthenticatorController

  $general_layout_path = 'layouts/backend/' + $theme + '/general'
     
  layout $general_layout_path
        
  def login_form_path
    "/authenticator/ldap/login"
  end
  
  def login
    if request.post?
      user = params[:login][:user]
      password = params[:login][:password]
      if user == "" || password == ""
        flash[:notice] = _("Empty Username and/or Password")
      else
        ldap = Net::LDAP.new :host => LDAP_CONFIG[RAILS_ENV]["host"],
                          :port => LDAP_CONFIG[RAILS_ENV]["port"].to_i,
                          :encryption => LDAP_CONFIG[RAILS_ENV]["encryption"].to_sym,
                          :base => LDAP_CONFIG[RAILS_ENV]["base"],
                          :auth=>{:method=>:simple, :username => user, :password => password } 
      
        begin      
          if ldap.bind
            users = ldap.search(:base => LDAP_CONFIG[RAILS_ENV]["base"], :filter => Net::LDAP::Filter.eq(LDAP_CONFIG[RAILS_ENV]["search_field"], "*#{user}"))
            if users.size == 1            
              u = User.find_by_login(user)
              if not u
                u = User.create(:login => user, :email => users.first.mail)
                role = Role.find_by_name("customer")
                InventoryPool.all.each do |ip|
                  u.access_rights.create(:inventory_pool_id => ip, :role => role, :level => 1)
                end
              end
              self.current_user = u
              redirect_back_or_default("/")
              return true
            else
              flash[:notice] = _("User unknown") if users.size == 0
              flash[:notice] = _("Too many users found") if users.size > 0
            end
          else
            flash[:notice] = _("Invalid username/password")
            redirect_to :action => 'login'
          end
        rescue Net::LDAP::LdapError
          flash[:notice] = _("Couldn't connect to LDAP: #{LDAP_CONFIG[:host]}:#{LDAP_CONFIG[:port]}")
        end
      end
    end
  end  
end