require 'net/http'
require 'uri'
require 'ftools'

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
		filename = '/var/rails/torrent_dam/public/data/' + user_id + '/' + name
		uri = URI.parse 'http://localhost:9091/transmission/rpc'
		Net::HTTP.new(uri.host, uri.port).start { |http|
			response = http.post '/transmission/rpc', {'method' => 'torrent-add', 'arguments' => {'filename' => filename}}.to_json
			if response.code == '401'
				return -1
			end
			if response.code == '409'
					response = http.post '/transmission/rpc', {'method' => 'torrent-add', 'arguments' => {'filename' => filename}}.to_json, response		
			end
			if response.code == '200'
				json_resp = JSON.parse response.body
				if json_resp['result'] == 'duplicate torrent'
 					p = fork {
						exec("transmissioncli -i " + path + ">/var/rails/torrent_dam/public/data/" + user_id + "/name")
					}
					Process.waitpid p
					f = File.open("/var/rails/torrent_dam/public/data/" + user_id + "/name", "r")
					while (!f.closed? && line = f.gets)
						if line.include? "name:"
							@torrent_name = line[6..line.length].chomp
							f.close
						end
					end
					Net::HTTP.new(uri.host, uri.port).start { |http|
						response = http.post '/transmission/rpc', {'method' => 'torrent-get', 'arguments' => {'fields' => ['id', 'name']}}.to_json
						if response.code == '409'
							response = http.post '/transmission/rpc', {'method' => 'torrent-get', 'arguments' => {'fields' => ['id', 'name']}}.to_json, response		
						end
						if response.code == '200'
							res = JSON.parse response.body
							res['arguments']['torrents'].each do |t|
									if t["name"] == @torrent_name
										return t['id']									
									end						
							end
						else 
							return -1
						end				
					}
				end
				if !json_resp['arguments']['torrent-added'].nil?
					return transmission_id = json_resp['arguments']['torrent-added']['id']
				end
				-1
			end
		}
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
	
	def del_torrent
		uri = URI.parse 'http://localhost:9091/transmission/rpc'
		Net::HTTP.new(uri.host, uri.port).start { |http|
			response = http.post '/transmission/rpc', {'method' => 'torrent-remove', 'arguments' =>  {'ids' => [self.transmission_id], 'delete-local-data' => true }}.to_json
			if response.code == '401'
				return -1
			end
			if response.code == '409'
					response = http.post '/transmission/rpc', {'method' => 'torrent-remove', 'arguments' => {'ids' => [self.transmission_id], 'delete-local-data' => true }}.to_json, response		
			end
			if response.code == '200'
				File.delete("/var/rails/torrent_dam/public/data/completed/" + self.t_hash + ".zip") if File.exist?("/var/rails/torrent_dam/public/data/completed/" + self.t_hash + ".zip")
			end
		}
	end
	
	def start_download(user_id, torrent)
		filename = '/var/rails/torrent_dam/public/data/' + user_id.to_s + '/' + sanitize_filename(torrent)
		uri = URI.parse 'http://localhost:9091/transmission/rpc'
		Net::HTTP.new(uri.host, uri.port).start { |http|
			response = http.post '/transmission/rpc', {'method' => 'torrent-add', 'arguments' => {'filename' => filename}}.to_json
			if response.code == '401'
				return -1
			end
			if response.code == '409'
					response = http.post '/transmission/rpc', {'method' => 'torrent-add', 'arguments' => {'filename' => filename}}.to_json, response		
			end
			if response.code == '200'
				json_resp = JSON.parse response.body
				if json_resp['arguments']['torrent-added'].nil?
					return -1
				end
				transmission_id = json_resp['arguments']['torrent-added']['id']
			end
		}
	end

	def check_status
		if File.exist?("/var/rails/torrent_dam/public/data/completed/" + self.transmission_id.to_s + ".zip")
			return 100
		else
			uri = URI.parse 'http://localhost:9091/transmission/rpc'
			Net::HTTP.new(uri.host, uri.port).start { |http|
				response = http.post '/transmission/rpc', {'method' => 'torrent-get', 'arguments' => {'ids' => [self.transmission_id], 'fields' => ['percentDone']}}.to_json
				if response.code == '401'
					return -1
				end
				if response.code == '409'
						response = http.post '/transmission/rpc', {'method' => 'torrent-get', 'arguments' => {'ids' => [self.transmission_id], 'fields' => ['percentDone']}}.to_json, response		
				end
				if response.code == '200'
					@res = JSON.parse response.body
				else 
					return -1
				end
			}
			status = @res['arguments']['torrents'][0]['percentDone']
			if (status == 100 && !File.exist?("/var/rails/torrent_dam/public/data/completed/" + self.transmission_id.to_s + ".zip"))
				p = fork {
							exec("cd /var/rails/torrent_dam/public/data/downloading; zip -r /var/rails/torrent_dam/public/data/completed/" + self.transmission_id.to_s + ".zip ./" + name)
						}
				Process.detach p
			end
			return status * 95
		end
		-1
	end

end
