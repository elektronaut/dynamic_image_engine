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
				belongs_to association_id, options

				# Overwrite the setter method
				class_eval <<-end_eval
					alias_method :associated_#{association_id}=, :#{association_id}=
					def #{association_id}=( image )
						# Convert a Tempfile to a proper Image
						begin
							if image.kind_of?( Tempfile ) || image.kind_of?( StringIO )
								image = Image.create( :imagefile => image )
							end
						rescue
						end
						# Quietly skip blank strings
						unless image.kind_of?( String ) && image.blank?
							self.associated_#{association_id} = image
						end
					end
				end_eval
			end 
			
		end # module
	end # module
end # module