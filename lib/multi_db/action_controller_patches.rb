class ActionController::Base
  prepend_before_filter :connect_to_organization_database
  
  # manually establish a connection to the proper database
  def connect_to_organization_database
    @org = nil
    
    # request is first priority
    if params[:org_code]
      if session[:org_code] && session[:org_code] != params[:org_code]
        reset_session
      end
      @org = MultiDB::Organization.active.where(:code => params[:org_code]).first
    end
    
    # try hostname if we don't already have a code in the session
    if !@org && !session[:org_code] && request && request.host
      @org ||= MultiDB::Organization.active.where(:code => $1.gsub('-', '_')).first if request.host =~ /^([-\w\d]+)/
      @org ||= MultiDB::Organization.active.includes(:hosts).where('organization_hosts.host = ?', request.host).first
    end
    
    if @org
      if session[:org_code] != @org.code
        session[:org_code] = @org.code
        session[:org_name] = @org.name
      end
    end
    
    if session[:org_code]
      @org ||= MultiDB::Organization.active.where(:code => session[:org_code]).first
      if @org
        ActiveRecord::Base.connect_to_organization(session[:org_code], true)
        return @org
      end
    end
    
    if Rails.env.test? && ENV['RAILS_ORG']
      @org ||= MultiDB::Organization.active.where(:code => ENV['RAILS_ORG']).first
      if @org
        ActiveRecord::Base.connect_to_organization(session[:org_code], true)
        return @org
      end
    end
    
    # if we don't issue an establish_connection by now, connect to default db (sessions)
    session[:org_code] = session[:org_name] = nil
    ActiveRecord::Base.connect_to_sessions
  end
  
  def connect_to_master_database
    ActiveRecord::Base.connect_to_master
  end
end
