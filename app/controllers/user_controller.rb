require 'ftools'

class UserController < ApplicationController

  before_filter :login_required, :only=>[ 'hidden', 'manage_account']
  before_filter :redirect_if_logged_in, :only => ['signup', 'login']
	ssl_required :login, :signup

  def signup
    if request.post?  
      @user = User.new(params[:user])
      if @user.save
				File.makedirs('/var/rails/torrent_dam/public/data/' + @user.id.to_s)
        session[:user_id] = User.authenticate(@user.email, @user.password)
        flash[:notice] = "Signup successful"
        redirect_to :cotroller => "torrent"          
      else
        flash[:notice] = "Signup unsuccessful"
      end
    end
  end

  def login
    if request.post?
      if session[:user_id] = User.authenticate(params[:user][:email], params[:user][:password])
        flash[:notice]  = "Login successful"
        redirect_to_stored
      else
        flash[:notice] = "Login unsuccessful"
      end
    end
  end

  def logout
    session[:user_id] = nil
    flash[:notice] = 'Logged out'
    redirect_to login_user_path
  end

  def change_account_info
		if request.post?
			@user = User.update(session[:user_id], params[:user])
			if @user.save
				flash[:notice]="Account Info Changed"
				redirect_to manage_account_user_path
			else
				flash[:notice]="Update Failed"
			end
		end
  end
  
  def manage_account
  end
end
