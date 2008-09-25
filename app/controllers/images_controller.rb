# Controller for the DynamicImage engine
class ImagesController < ApplicationController
	
	# Return the requested image. Rescale, filter and cache it where appropriate.
	def view_image
		minTime = Time.rfc2822( request.env[ "HTTP_IF_MODIFIED_SINCE" ] ) rescue nil

		image = Image.find( params[:id] ) rescue nil
		unless image
			if self.respond_to?( :render_error )
				render_error 404 and return
			else
				render :status => 404, :text => "404: Image not found" and return
			end
		end

		if minTime && image.created_at? && image.created_at <= minTime
			render :text => '304 Not Modified', :status => 304
			return
		end
		
		if size = params[:size]
		    if size =~ /^x[\d]+$/ || size =~ /^[\d]+x$/
		        size = Vector2d.new(size)
			    image_size = Vector2d.new( image.size )
			    size = image_size.constrain_both(size).round.to_s
			end
    		imagedata = CachedImage.get_cached(image, size, params[:filterset])
	    else
    		imagedata = image
        end


		if image
			response.headers['Cache-Control'] = nil
			response.headers['Last-Modified'] = imagedata.created_at.httpdate if imagedata.created_at?
			send_data( 
				imagedata.data, 
				:filename    => image.filename, 
				:type        => image.content_type, 
				:disposition => 'inline'
			)
		end
		
	end

end
