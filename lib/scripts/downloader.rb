require 'net/ftp'
require 'timeout'
require 'zlib'

class Downloader
	attr_accessor :ftp

	def host
		'on.tmsgf.trb'
	end

	def username
		'oninpdev'
	end

	def password
		'432ny154'
	end

    def get_files(file_names)
        connect_to_ftp

        file_names.each do |filename|
            filename += ".gz"

            anly = false
            filename.include?('anly') ? anly = true : anly = false

            ftp.chdir('anly') if anly

            Timeout.timeout(50000) do
                progress = 0
                size = ftp.size(filename)

                #download it
                ftp.getbinaryfile(filename, "tmp/#{filename}") do |chunk|
                    progress += chunk.size
                    STDOUT.write "Downloading #{filename}: #{progress * 100 / size}%\r"
                end

                #unzip it to xml
                puts "\nUnzipping #{filename}"
                Zlib::GzipReader.open("tmp/#{filename}") do |gz|
                    File.open("tmp/#{filename[0..(filename.length-4)]}", "w") do |g|
                        IO.copy_stream(gz, g)
                    end
                end
            end

            #delete gzip file
            File.delete("tmp/#{filename}")

            ftp.chdir('/On2') if anly
        end

        ftp.close
    end
 
    def connect_to_ftp
        if ftp.nil? || ftp.closed?
            self.ftp = Net::FTP.new(host, username, password)
            ftp.passive = true
            ftp.chdir('On2')
        end
    end
end