require 'dynamic_image/filterset'

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
								img_obj = Image.create( :imagefile => img_obj )
							end
						rescue
							# Do nothing
						end
						# Convert a Tempfile to a proper Image
						case img_obj
						when StringIO, File
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