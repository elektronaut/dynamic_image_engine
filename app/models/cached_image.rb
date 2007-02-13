

# Resized and filtered images are stored in the cached_images table.
class CachedImage < ActiveRecord::Base
	belongs_to :image
	
	
	
	# Purge all cached data (with optional conditions).
	def self.clear_cache( conditions = nil )
		CachedImage.delete_all( conditions )
	end



	# Get or generate a CachedImage object. image and filterset should be objects, size can be
	# any Vector2d compatible type (ie, String, Numeric or Array).
	def self.get_cached( image, size, filterset=nil )
		size       = Vector2d.new( size ).round.to_s
		conditions = { :image_id => image.id, :size => size }
		conditions[:filterset] = filterset || 'default'
		
		cached_image = CachedImage.find( :first, :conditions => [ "image_id = ? AND size = ? AND filterset = ?", conditions[:image_id], conditions[:size], conditions[:filterset] ] ) 
		unless cached_image
			cached_image           = CachedImage.new
			cached_image.image     = image
			cached_image.size      = size
			cached_image.filterset = filterset || 'default'
			cached_image.data      = image.rescaled_and_cropped_data( size )
			cached_image.apply_filters
			cached_image.save
		end
		cached_image
	end
	


	# Apply filters to the image data. If no filter set is specified, this method will look
	# for a set called "default" and apply it.
	def apply_filters
	
		filterset_name = self.filterset || 'default'
		
		filterset = ActsAsDynamicImage::Filterset[filterset_name]
		
		if filterset
			data = Magick::ImageList.new.from_blob( self.data )
			data = filterset.process( data )
			self.data = data.to_blob
		end
	end

end
