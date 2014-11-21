class CreateImages < ActiveRecord::Migration
  	def change
    	create_table :images do |t|
    		t.string :tms_id
    		t.string :image_type
      		t.string :title
      		t.string :title_lang
      		t.string :desc_lang
      		t.string :caption_lang
      		t.string :url
      		t.string :main_title_lang
      		t.string :is_good
    	end
  	end
end
