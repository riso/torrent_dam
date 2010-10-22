class AddTransmissionIdToTorrents < ActiveRecord::Migration
  def self.up
		add_column :torrents, :transmission_id, :integer
  end

  def self.down
		remove_column :torrents, :transmission_id
  end
end
