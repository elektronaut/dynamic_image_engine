# Load prerequisites
require 'RMagick'
require 'vector2d'

# Include hook code here
require 'dynamic_image'

# Evil, evil hack to support reloading of models
begin
	# Rails 2.0
	Rails::Plugin.class_eval do
		def reloadable!
			load_paths.each { |p| Dependencies.load_once_paths.delete(p) }
		end
	end
	reloadable!
rescue
	# Rails 1.x
end