class AddHashToTorrents < ActiveRecord::Migration
  def self.up
    add_column :torrents, :t_hash, :string
  end

  def self.down
    remove_column :torrents, :hash
  end
end
