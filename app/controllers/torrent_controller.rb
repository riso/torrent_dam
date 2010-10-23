class TorrentController < ApplicationController
  
  before_filter :login_required
  
  def index
	if @user != nil
		@torrents = @user.torrents
		@t_status = Hash.new
		for t in @torrents
			@t_status[t.id.to_s] = t.check_status @user.id.to_s, t.t_hash		
		end
	else 
		redirect_to :controller => 'user', :action => 'login'
	end
  end
  
  def new
		@torrent = @user.torrents.build
		if request.post?
			hash = @torrent.store(params[:new][:torrent], @user.id.to_s)
			@torrent = @user.torrents.build(:name => params[:new][:torrent].original_filename.to_s, :t_hash => hash)
			if @torrent.save
				flash[:notice]='torrent uploaded correctly'
				redirect_to :action => 'index'
			else
				flash[:notice]='error uploading torrent'
			end
		end
  end
  
  def destroy
		if destroy_torrent params[:id]
			redirect_to :action => 'index'
		else
			flash[:notice] = 'Error Deleting Torrent'
		end
  end
  
  def download
		id = dl_torrent params[:id], session[:user_id]
		if id == -1
			flash[:notice] = 'Error Downloading Torrent'
		else 
			flash[:notice] = 'Download Started' 
			@torrent.update_attributes({:transmission_id => id})
		end
		redirect_to :action => 'index'
  end

  def retrieve
		if !ret_torrent params[:id]
				flash[:notice] = 'Torrent Is Still Downloading'
				redirect_to :action => 'index'	
		end
  end

end

