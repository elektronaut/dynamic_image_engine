require 'vector2d'

class Image < ActiveRecord::Base

	belongs_to :author,
			   :class_name     => 'User',
			   :foreign_key    => 'user_id'
			
	belongs_to :binary
			
	has_many   :cached_images, :dependent => :delete_all

	validates_format_of :content_type, 
	                    :with => /^image/,
		                :message => "you can only upload pictures"
	

	# Images larger than this will be rescaled down
	MAXSIZE = "1280x1024"
	
	#def self.datetime_for_id( id )
	#	datetime = self.connection.select_one( "SELECT created_at FROM "+self.table_name+" WHERE id = "+self.connection.quote( id ) )['created_at']
	#	datetime = ActiveRecord::ConnectionAdapters::Column.string_to_time( datetime )
	#end

	def before_save
		self.title    = File.basename( self.filename, ".*" ) if self.title == ""
		self.filename = friendly_file_name( self.filename )
		check_image_data
	end
	
	def data
		self.binary.data rescue nil
	end
	
	def data=( blob )
		unless self.binary
			self.binary = Binary.new
			self.binary.linkable = self
		end
		self.binary.data = blob
		self.binary.save
	end
	
	def data?
		( self.binary && self.binary.data? ) ? true : false
	end
	
	def imagefile=( image_file )
		self.filename     = image_file.original_filename rescue File.basename( image_file.path )
		self.content_type = image_file.content_type.chomp rescue "image/"+image_file.path.split(/\./).last.gsub(/jpg/,"jpeg") # hack hack hack

		unless self.binary
			self.binary = Binary.new
			#self.binary.linkable = self
		end

		self.binary.data         = image_file.read
		self.binary.save
	end
	
	def hotspot
		( Vector2d.new( self.size ) * 0.5 ).round.to_s
	end
	
	def check_image_data
		if self.data?
			image     = Magick::ImageList.new.from_blob( self.data )
			size      = Vector2d.new( image.columns, image.rows )
			maxsize   = Vector2d.new( MAXSIZE )
			if ( size.x > maxsize.x || size.y > maxsize.y )
				size = size.constrain_both( maxsize ).round
				image.resize!( size.x, size.y )
				self.data = image.to_blob
			end
			self.size = size.round.to_s
		end
	end
	
	
	def constrain_size( *max_size )
		Vector2d.new( self.size ).constrain_both( max_size.flatten ).round.to_s
	end
	
	
	# Convert file name to a more file system friendly one.
	# TODO: international chars
	def friendly_file_name( file_name )
		[ ["æ","ae"], ["ø","oe"], ["å","aa"] ].each do |int|
			file_name = file_name.gsub( int[0], int[1] )
		end
		File.basename( file_name ).gsub( /[^\w\d\.-]/, "_" )
	end
	
	def base_part_of(file_name)
		name = File.basename(file_name)
		name.gsub(/[ˆ\w._-]/, '')
	end
	
	
	def rescaled_and_cropped_data( *args )
		data         = Magick::ImageList.new.from_blob( self.data )
		size         = Vector2d.new( self.size )
		rescale_size = size.dup.constrain_one( args ).round                             # rescale dimensions
		crop_size    = Vector2d::new( args )                                            # crop size
		new_hotspot  = Vector2d::new( hotspot ) * ( rescale_size / size )               # recalculated hotspot
		rect = [ (new_hotspot-(crop_size/2)).round, (new_hotspot+(crop_size/2)).round ] # array containing crop coords
			  
		#adjustments
		x = rect[0].x; rect.each { |r| r.x += (x.abs) }            if ( x < 0 ) 
		y = rect[0].y; rect.each { |r| r.y += (y.abs) }            if ( y < 0 ) 
		x = rect[1].x; rect.each { |r| r.x -= (x-rescale_size.x) } if ( x > rescale_size.x ) 
		y = rect[1].y; rect.each { |r| r.y -= (y-rescale_size.y) } if ( y > rescale_size.y ) 
		
		rect[0].round!
		rect[1].round!

		data = data.resize( rescale_size.x, rescale_size.y ).crop( rect[0].x, rect[0].y, crop_size.x, crop_size.y )
		data.to_blob{ self.quality = 90 }
	end
	
	
	
	
end
