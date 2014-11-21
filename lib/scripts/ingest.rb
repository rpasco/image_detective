require_relative 'downloader'
require 'open-uri'
require 'net/https'
require 'nokogiri'

t1 = Time.now

if ARGV.empty?
	countries = ["bra"]
else
	countries = ARGV[0].split(',')
end

date = Date.today.to_s.tr('-', '')

files = []
countries.each { |country| files << "on_#{country}_tv_programs_v22_#{date}.xml" }

ftp_transfer = Downloader.new
ftp_transfer.get_files(files)

images = []
batch_size = 1000

files.each do |filename|
	doc = Nokogiri::XML.Reader(open("tmp/#{filename}"))

	doc.each do |node|
		if node.name == "program" && node.node_type == 1
			program = Nokogiri::XML.parse(node.outer_xml)

			program.search('asset').each do |asset|
				if asset["category"] == "Poster Art" && asset["assetId"].include?('_v7_')
					image = Hash.new
					image[:tms_id] 		 = program.at('program')["TMSId"]
					image[:image_type] 	 = "Poster Art"
					image[:title] 		 = program.at("titles title[type='full']").inner_text
					image[:title_lang] 	 = program.at("titles title[type='full']")["lang"]
					image[:desc_lang] 	 = program.at('desc')["lang"] if program.at('desc')
					image[:caption_lang] = asset.at('caption')["lang"]
					image[:url] 		 = "http://tmsimg.com/assets/#{asset["assetId"]}.jpg"
					image[:is_good] 	 = 'Y'

					#get main title lang from Ned Data Services
					url  = URI("http://qb-nedserv.casttv.com/NedDataServices/programs/#{program.at('program')["rootId"]}")
					req  = Net::HTTP::Get.new(url)
					req.basic_auth  'icecream', 'social'
					res  = Net::HTTP.start(url.hostname, url.port) { |http| http.request(req) }
					page = res.body
					doc  = JSON.parse(page)

					image[:main_title_lang] = doc['titles'].find { |title| title["type"] == "MAIN" }['language'] if doc['titles']

					images << Image.new(image)

					if images.size >= batch_size
						Image.import(images)
						images = []
					end

				end
			end
		end
	end
end

Image.import(images)