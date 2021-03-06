class CreateImages < ActiveRecord::Migration
	def self.up
		create_table :images do |t|
			t.column :name,         :string
			t.column :byline,       :string
			t.column :filename,     :string
			t.column :content_type, :string
			t.column :size,         :string
			t.column :hotspot,      :string
			t.column :binary_id,    :integer
			t.column :created_at,   :datetime
			t.column :updated_at,   :datetime
			t.column :filters,      :text
		end
	end

	def self.down
		drop_table :images
	end
end
