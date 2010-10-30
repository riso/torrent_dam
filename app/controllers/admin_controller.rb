require 'ftools'

class AdminController < ApplicationController

	before_filter :login_required
	ssl_required :index, :users, :delete_user, :new_user, :show_user_torrent, :delete_torrent, :download_torrent, :new_user_torrent, :retrieve_torrent, :torrents

	def index
	end
	
	def users
		@users = User.all
	end

	def delete_user
		@user = User.find(params[:id])
		@torrents = @user.torrents
		if @user.destroy
			for t in @torrents
				destroy_torrent t.id
			end
			redirect_to :action => 'users'
		else
			flash[:notice] = 'Error Deleting User'
		end
	end
	
	def new_user
    if request.post?  
      @user = User.new params[:user]
      if @user.save
				File.makedirs('/var/rails/torrent_dam/public/data/' + @user.id.to_s)
        flash[:notice] = "User Added"
        redirect_to :action => 'users'         
      else
        flash[:notice] = "Error Adding User"
      end
    end
	end

	def show_user_torrent
		@user = User.find params[:id]
		@torrents = @user.torrents
		@t_status = Hash.new
		for t in @torrents
			@t_status[t.id.to_s] = t.check_status @user.id.to_s, t.t_hash		
		end
	end

	def delete_torrent	
		if destroy_torrent params[:id]
			redirect_to :back
		else
			flash[:notice] = 'Error Deleting Torrent'
		end
	end

	def download_torrent
		if !dl_torrent params[:id], params[:uid]
			flash[:notice] = 'Error Downloading Torrent'
		else 
			flash[:notice] = 'Download Started' 
		end
		redirect_to :back
	end

	def new_user_torrent
		if request.post?
			@user = User.find session[:edit_user]
			@torrent = Torrent.new
			t_hash = @torrent.store params[:new][:torrent], @user.id.to_s
			@torrent = @user.torrents.build :name => params[:new][:torrent].original_filename.to_s, :t_hash => t_hash
			if @torrent.save
				flash[:notice]='Torrent Uploaded Correctly'
				session[:edit_user] = nil
				redirect_to :action => 'show_user_torrent', :id => @user.id
			else
				flash[:notice]='Error Uploading Torrent'
			end
		else
			@user = User.find params[:uid]
			session[:edit_user] = @user.id
			@torrent = @user.torrents.build
		end
	end


	def retrieve_torrent
		if !ret_torrent params[:id]
			flash[:notice] = 'Torrent Download Isn\'t Finished Yet'
		end
	end
	
	def torrents
		@torrents = Torrent.all
		@t_status = Hash.new
		for t in @torrents
			@t_status[t.id.to_s] = t.check_status
		end
	end

end
