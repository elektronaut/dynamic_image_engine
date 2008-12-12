require 'dynamic_image/filterset'

module DynamicImage
	@@dirty_memory = false
	
	class << self
		
		def dirty_memory=(flag)
			@@dirty_memory = flag
		end
		
		def dirty_memory
			@@dirty_memory
		end
		
		# RMagick stores image data internally, Ruby doesn't see the used memory.
		# This method performs garbage collection if @@dirty_memory has been flagged.
		# More details here: http://rubyforge.org/forum/message.php?msg_id=1995
		def clean_dirty_memory(options={})
			options.symbolize_keys!
			if @@dirty_memory || options[:force]
				gc_disabled = GC.enable
				GC.start
				GC.disable if gc_disabled
				@@dirty_memory = false
				true
			else
				false
			end
		end
	end
end

module ActiveRecord
	module Associations
		
		# ActiveRecord::Associations::ClassMethods is monkey patched in order to enable the
		# <tt>belongs_to_image</tt> macro in all ActiveRecord models.
		module ClassMethods

			# By using <tt>belongs_to_image</tt> over <tt>belongs_to</tt>, you gain the ability to
			# set the image directly from an uploaded file. This works exactly like <tt>belongs_to</tt>,
			# except the class name will default to 'Image' - not the name of the association.
			# 
			# Example:
			#
			#   # Model code
			#   class Person < ActiveRecord::Base
			#     belongs_to_image :mugshot
			#   end
			#
			#   # View code
			#   <% form_for 'person', @person, :html => { :multipart => true } do |f| %>
			#     <%= f.file_field :mugshot %>
			#   <% end %>
			#
			def belongs_to_image( association_id, options={} )
				options[:class_name] ||= 'Image'
				options[:foreign_key] ||= options[:class_name].downcase+'_id'
				belongs_to association_id, options

				# Overwrite the setter method
				class_eval <<-end_eval
					alias_method :associated_#{association_id}=, :#{association_id}=
					def #{association_id}=( img_obj )
						# Hack
						begin
							case img_obj
							when StringIO, Tempfile, ActionController::UploadedTempfile, File
								DynamicImage.dirty_memory = true # Flag for GC
								img_obj = Image.create( :imagefile => img_obj )
							end
						rescue
							# Do nothing
						end
						# Convert a Tempfile to a proper Image
						case img_obj
						when StringIO, File
							DynamicImage.dirty_memory = true # Flag for GC
							img_obj = Image.create( :imagefile => img_obj )
						end
						# Quietly skip blank strings
						unless img_obj.kind_of?( String ) && img_obj.blank?
							self.associated_#{association_id} = img_obj
						end
					end
				end_eval
			end 
			
		end # module
	end # module
end # module