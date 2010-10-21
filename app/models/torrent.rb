require 'transmission-client'

class Torrent < ActiveRecord::Base
	validates_presence_of :name, :user_id 
	belongs_to :user
	validates_uniqueness_of :name, :scope => :user_id , :message => 'already uploaded!'
	validates_format_of :name, :with => /(\w)*.[^(torrent)]/i, :message => 'not a torrent file!'
	
	def store(upload, user_id)
		name = sanitize_filename upload.original_filename
		directory = "/var/rails/torrent_dam/public/data/" + user_id + "/"
		path = File.join(directory, name)
		f = File.open(path, "wb")
		f.write(upload.read)
		f.close
		p = fork {
			exec("transmissioncli -i " + path + ">/var/rails/torrent_dam/public/data/" + user_id + "/hash")
		}
		Process.waitpid p
		f = File.open("/var/rails/torrent_dam/public/data/" + user_id + "/hash", "r")
		while (line = f.gets)
			if line.include? "hash:"
				return line[6..line.length].chomp
			end
		end
	end

	def sanitize_filename(filename)
  returning filename.strip do |name|
    # NOTE: File.basename doesn't work right with Windows paths on Unix
    # get only the filename, not the whole path
    name.gsub! /^.*(\\|\/)/, ''
    # Finally, replace all non alphanumeric, underscore
    # or periods with underscore
    name.gsub! /[^\w\.\-]/, '_'
  end
end
	
	def del_torrent(t_hash)
		p = fork { 
			exec("transmission-remote -t" + t_hash + " --remove-and-delete")
		}
		Process.detach p
		File.delete("/var/rails/torrent_dam/public/data/completed/" + t_hash + ".zip") if File.exist?("/var/rails/torrent_dam/public/data/completed/" + t_hash + ".zip")
	end
	
	def start_download(user_id, torrent)
		 EventMachine.run do
			c = Transmission::Client.new
			c.add_torrent_by_file("/var/rails/torrent_dam/public/data/" + user_id.to_s + "/" + sanitize_filename(torrent))
			EventMachine.stop_event_loop
		end
		#p = fork{
			#exec("transmission-remote -a /var/rails/torrent_dam/public/data/" + user_id.to_s + "/" + sanitize_filename(torrent))
		#}
		#Process.detach p
	end

	def check_status(user_id, t_hash)
		if File.exist?("/var/rails/torrent_dam/public/data/completed/" + t_hash + ".zip")
			return 100
		else
			p = fork {
				exec("transmission-remote -t" + t_hash + " -i >/var/rails/torrent_dam/public/data/" + user_id + "/status")
			}
			Process.waitpid p
			f = File.open("/var/rails/torrent_dam/public/data/" + user_id + "/status", "r")
			while (line = f.gets)
				if line.include? "Name:"
					name = line[8..line.length].chomp
				end
				if line.include? "Percent Done:"
					status = line[16..line.length].chomp.to_i
					if (status == 100 && !File.exist?("/var/rails/torrent_dam/public/data/completed/" + t_hash + ".zip"))
						p = fork {
							exec("transmission-remote -t" + t_hash + " -S; cd /var/rails/torrent_dam/public/data/downloading; zip -r /var/rails/torrent_dam/public/data/completed/" + t_hash +".zip ./" + name + "; transmission-remote -t" + t_hash + " --remove-and-delete")
						}
						Process.detach p
					end	
					return status * 0.95
				end
			end
		end
		-1
	end

end
