class CreateCachedImages < ActiveRecord::Migration
	def self.up
		create_table :cached_images do |t|
			t.column :image_id,   :integer
			t.column :filterset,  :string
			t.column :size,       :string
			t.column :created_at, :datetime
			t.column :updated_at, :datetime
			t.column :data,       :binary, :limit => 100.megabytes
		end
	end

	def self.down
		drop_table :cached_images
	end
end
