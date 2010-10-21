class AddCompleteToTorrents < ActiveRecord::Migration
  def self.up
    add_column :torrents, :complete, :boolean, :default => 0
  end

  def self.down
    remove_column :torrents, :complete
  end
end
