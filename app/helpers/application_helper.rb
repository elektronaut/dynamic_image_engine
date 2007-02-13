module ApplicationHelper

	# Returns an hash consisting of the URL to the dynamic image and parsed options.
	def dynamic_image_options( image, options = {} )
		# TODO: use url_for to get the proper image url from routing
		options.symbolize_keys!
		options[:crop] = false unless options[:crop] == true
		
		url = "/dynamic_image/"
		#url = ""

		url << image.id.to_s << "/"


		if options[:size]
			options[:size] = Vector2d.new( image.size ).constrain_both( options[:size] ).round.to_s unless ( options[:crop] )
			url << options[:size] << "/" if options[:size]
		end
		options.delete :crop

		if options[:filterset]
			url << options[:filterset] << "/"
			options.delete :filterset
		end

		url << image.filename

		if options[:no_size_tags]
			options.delete :no_size_attr
			options.delete :size
		end

		options[:alt] ||= image.title if image.title?
		options[:alt] ||= image.filename.split('.').first.capitalize
		
		{ :url => url, :options => options }
	end
	
	
	
	# Returns an image tag for the provided image model, works similar to the rails <tt>image_tag</tt> helper. 
	# The <tt>alt</tt> tag is set to the image title unless explicitly provided.
	#
	# == Examples
	#
	# Tag for original image, without rescaling:
	#   <%= dynamic_image_tag( @image ) %>
	#
	# Tag for image, rescaled to fit within 100x100 (size will be 100x100 or smaller):
	#   <%= dynamic_image_tag( @image, :size => "100x100" ) %>
	#
	# Tag for image, cropped and rescaled to 100x100 (size will be 100x100 in all cases):
	#   <%= dynamic_image_tag( @image, :size => "100x100", :crop => true ) %>
	#
	# Tag for image with a filter set applied:
	#   <%= dynamic_image_tag( @image, :size => "100x100", :filterset => @filterset ) %>
	#
	# Tag for image with a named filter set applied:
	#   <%= dynamic_image_tag( @image, :size => "100x100", :filterset => "thumbnails" ) %>
	#
	# Tag for image without the width/height attributes, and with a custom alt attribute
	#   <%= dynamic_image_tag( @image, :size => "100x100", :no_size_attr => true, :alt => "Thumbnail for post" %>
	
	def dynamic_image_tag( image, options = {} )
		parsed_options = dynamic_image_options( image, options )
		image_tag( parsed_options[:url], parsed_options[:options] ).gsub(/\?[\d]+/,'')
	end


	
	# Returns an url corresponding to the provided image model.
	# Special options are documented in ApplicationHelper.dynamic_image_tag, only <tt>:size</tt>, <tt>:filterset</tt> and <tt>:crop</tt> apply.
	def dynamic_image_url( image, options = {} )
		parsed_options = dynamic_image_options( image, options )
		parsed_options[:url]
	end
end