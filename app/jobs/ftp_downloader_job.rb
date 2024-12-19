class FtpDownloaderJob < ApplicationJob
  queue_as :default
  require 'net/ftp'
  require 'fileutils'
  require 'date'


  def perform(downloader)


    #finds the download source info from the database and sets it to the variable download_source
    download_source = Downloader.find(downloader)
    logger.info "setting downloader to processing"

    #find the ftp info from the database and set it to the variable file_settings
    file_settings = Setting.find(download_source.setting)
    logger.debug "#{download_source.processing_status}"
    
    #set the job processing status to true to display in the frontend that the job is running
    download_source.processing_status = "true"

    logger.debug "setting job start time"
    #set the start time of the download process
    download_source.start_time = Time.now
    download_source.save

    logger.debug "setting downloader with ID #{downloader} processing set to #{download_source.processing_status.to_s}"
    logger.info "Starting downloader"
    logger.debug "FTP Instance name: #{download_source.setting.instance_name}"

    #create FTP session and download files
    ftp = Net::FTP.new
    ftp.connect(download_source.setting.ftp_server, download_source.setting.ftp_port)
    ftp.login(download_source.setting.username, download_source.setting.ftp_password)
    ftp.chdir(download_source.ftp_path)
    ftp.passive = true
    file_list = ftp.nlst

    #check if we have renaming enabled, if yes, set the final path to the renamed path. 
    if download_source.rename == true
      logger.debug "renaming is enabled"
      final_path = "#{download_source.setting.download_path}/#{download_source.rename_prefix}"
    else
      logger.debug "rename dissabled, saving to mounts without prefix."
      final_path = "#{download_source.setting.download_path}/"
    end


    #for each file, check if the server file is newer than the most recent file we downloaded. If it is this begins the download process.
    file_list.each do |file|
      logger.debug "found file #{file}"
      date_modified = ftp.mdtm(file)

      logger.debug "last modified (unix time): #{date_modified} "
      #check if we know about this file, if yes verify that the server version is newer
      if FileListing.find_by(file_name: file).present?

        logger.info "file (#{file}), found in databse."

        if FileListing.find_by(file_name: file).last_modified < date_modified

          logger.info "^^#{file} is newer on FTP source than in our databse, downloading updated file"
          logger.debug "file is #{download_source.setting.instance_name} / #{download_source.ftp_path}/#{file}"

          ftp.getbinaryfile(file, "#{download_source.setting.temporary_download_path}/#{file}")

          DownloadLogger.info "downloaded #{file} at #{Time.now} - FTP Newer"

          logger.debug "downloaded, moving file to #{final_path}#{file}"
          logger.debug "sleeping for 3 seconds"

          #TODO improve this! For now its just a pause to allow everything to catch up.
          sleep 3
          
          #copy the file to the final location
          FileUtils.cp("#{download_source.setting.temporary_download_path}/#{file}", "#{final_path}#{file}")
        
          logger.debug "updating file_listings database with new date modified"
          

          logger.debug "updating file_listings database with new date modified"
          update_file_db("#{file}", "#{date_modified}", "#{download_source.setting.ftp_server}")


        else
          logger.debug "new file, downloading #{file}"
        
          ftp.getbinaryfile(file, "#{download_source.setting.temporary_download_path}/#{file}")
        
          DownloadLogger.info "downloaded #{file} at #{Time.now} - Never before seen"
          logger.info  "new file downloaded #{file}"
          logger.debug "sleeping for 3 seconds"
        
          sleep 3
        

        FileUtils.cp("#{download_source.setting.temporary_download_path}/#{file}", "#{final_path}#{file}")

        logger.debug "creating new file listing"
        
        #update the file listnings database
        new_file_db("#{file}","#{date_modified}","#{ftp.pwd}")

        
        filedata.save
      

      end
      
      #copy the file to a secondary location if backup is enabled.
      if download_source.backup == true
        date_dir = Date.today.strftime(%Y-%m-%d)
        logger.debug "backup is enabled"
        logger.info "Backup location is: #{download_source.backup_path}/#{file}"
        FileUtils.cp("#{download_source.setting.temporary_download_path}/#{file}", "#{download_source.backup_path}/#{date_dir}/#{file}")
      
      else
        logger.debug "backup is not enabled"
      end
    end
    logger.info "closing FTP session!"
    
    ftp.close
    
    logger.info "removing processing_status"

    #logger.debug download_source.processing_status
    download_source.processing_status = "false"
    download_source.save
    #dl_status = download_source.processing_status.to_s
    logger.debug "setting downloader with ID #{downloader} processing set to #{download_source.processing_status.to_s}"

  end
  logger.info "Done with FTP downloading Job"
  puts "DONE!"


end



def backup_files(bkup_path, temp_path, file)
  logger.debug "backup is enabled, copying the files to a backup server"
      date_dir = Date.today.strftime("%Y-%m-%d")
      logger.debug "backup is enabled"
      logger.info "Creating Backup location: #{bkup_path}/#{date_dir}/#{file}"

      FileUtils.mkdir_p("#{bkup_path}/#{date_dir}")

      FileUtils.cp("#{temp_path}/#{file}", "#{bkup_path}/#{date_dir}/#{file}")
      logger.info "backup complete"
end

def update_file_db(file, date_modified, ftp_file_path)
  logger.debug "updating file listing"
  filedata = FileListing.find_by(file_name: file)
  filedata.last_modified = date_modified
  filedata.file_path = ftp_file_path
  logger.debug "saving database entry"
  filedata.save
end

def new_file_db(file, date_modified, ftp_file_path)
  logger.debug "creating new file listing"
  filedata = FileListing.new
  filedata.file_name = file
  filedata.last_modified = date_modified
  filedata.file_path = ftp_file_path
  logger.debug "saving new file listing"
  filedata.save
end

