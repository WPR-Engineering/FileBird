class ManualDownloadJob < ApplicationJob
  queue_as :default
  queue_as :default
  require 'net/ftp'
  require 'fileutils'
  require 'date'


  def perform(downloader)



    download_source = Downloader.find(downloader)

    logger.debug "current processing status:#{download_source.processing_status}"

    logger.info "setting downloader to processing"


    download_source.processing_status = "true"

    logger.debug "setting job start time"
    download_source.start_time = Time.now
    download_source.save
    logger.debug "setting downloader with ID #{downloader} processing set to #{download_source.processing_status.to_s}"

    logger.info "Starting downloader"
    logger.debug "FTP Instance name: #{download_source.setting.instance_name}"
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




    file_list.each do |file|
      logger.debug "found file #{file}"
      date_modified = ftp.mdtm(file)
      logger.debug "last modified (unix time): #{date_modified} "
      if FileListing.find_by(file_name: file).present?
        logger.info "file (#{file}), found in databse."

          logger.info "^^^^^^^^^^^^^^^^Manual Re-Download^^^^^^^^^^^^^^^^^^^^^^"
          logger.debug "file is on FTP server #{download_source.setting.instance_name} Path is: #{download_source.ftp_path}/#{file}"

          ftp.getbinaryfile(file, "#{download_source.setting.temporary_download_path}/#{file}")
          
          DownloadLogger.info "downloaded #{file} at #{Time.now} - Manual Download"
          logger.debug "downloaded, copying file to #{final_path}#{file}"

          FileUtils.cp("#{download_source.setting.temporary_download_path}/#{file}", "#{final_path}#{file}")

          logger.debug "updating file_listings database with new date modified"
          update_file_db("#{file}", "#{date_modified}", "#{download_source.setting.ftp_server}")
      else
        logger.info "Manual download of new files started"
        logger.debug "new file, downloading #{file}"

        ftp.getbinaryfile(file, "#{download_source.setting.temporary_download_path}/#{file}")

        DownloadLogger.info "downloaded #{file} at #{Time.now} - Manual Download (never before seen)"
        logger.info  "new file downloaded #{file}"

        logger.debug "moving to final direcotry"


        FileUtils.cp("#{download_source.setting.temporary_download_path}/#{file}", "#{final_path}#{file}")

        #update the file listnings database
        new_file_db("#{file}","#{date_modified}","#{ftp.pwd}")

      end
    #copy the file to a secondary location if backup is enabled.
      if download_source.backup == true
       logger.debug "running backup method"
        backup_files("#{download_source.backup_path}", "#{download_source.setting.temporary_download_path}", "#{file}")
      else
        logger.debug "backup is not enabled"
      end

      logger.info "cleaning up files"
      FileUtils.rm("#{download_source.setting.temporary_download_path}/#{file}")
    end
    
    logger.info "closing FTP session!"
    ftp.close


    logger.info "removing processing_status"

    #logger.debug download_source.processing_status
    download_source.processing_status = "false"
    download_source.save
    #dl_status = download_source.processing_status.to_s
    logger.debug "setting downloader with ID #{downloader} processing set to #{download_source.processing_status.to_s}"
  logger.info "Done with FTP downloading Job"


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

