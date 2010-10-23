# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.


class ApplicationController < ActionController::Base
	include SslRequirement
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details
  before_filter :find_active_user

	def ssl_required?
		return false if RAILS_ENV == 'test'
		super
	end
  
  def redirect_if_logged_in
	if session[:user_id] && User.exists?(session[:user_id])
		redirect_to :controller => "torrent"
	end
  end
 
  def find_active_user
	if session[:user_id] && User.exists?(session[:user_id])
		@user = User.find(session[:user_id])
	else
		@user = nil
	end
  end
  
  def login_required
    if session[:user_id]
      return true
    end
    flash[:notice]='Please login to continue'
    session[:return_to]=request.request_uri
    redirect_to :controller => "user", :action => "login"
    return false 
  end

  def current_user
    session[:user_id]
  end

  def redirect_to_stored
    if return_to = session[:return_to]
      session[:return_to]=nil
      redirect_to return_to
    else
      redirect_to :controller=>"torrent"
    end
  end

	def destroy_torrent(t_id)
		@torrent = Torrent.find t_id
		t_hash = @torrent.t_hash
		@t = Torrent.find :all, :conditions => ["t_hash = ?", t_hash]
		if (@t.count == 1)
			@torrent.del_torrent
		end
		return @torrent.destroy
  end

	def dl_torrent (t_id, u_id)
		@torrent = Torrent.find t_id
		return @torrent.start_download u_id, @torrent.name
	end

	def ret_torrent(t_id)
		@torrent = Torrent.find t_id
		name = "/var/rails/torrent_dam/public/data/completed/" + @torrent.t_hash + ".zip"
		if File.exist? name
			send_file name, :type=>"application/zip"
			return true
		end
		false
	end

end
