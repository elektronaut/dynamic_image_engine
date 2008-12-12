connect 'dynamic_image/:id/:size/:filterset/*filename', :controller => 'images', :action => 'render_dynamic_image', :requirements => { :size => /[\d]*x[\d]*/ }
connect 'dynamic_image/:id/:size/*filename',            :controller => 'images', :action => 'render_dynamic_image', :requirements => { :size => /[\d]*x[\d]*/ }
connect 'dynamic_image/:id/*filename',                  :controller => 'images', :action => 'render_dynamic_image'
