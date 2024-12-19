# FileBird - FTP manager for broadcast services

# Notes


* Currently the FTP password is stored in plain text in the DB, this will be fixed soon, but due to time it is not implimented properly.
* you need to run redis on your server

# setup

app can be deployed with capistrano

1. make your server
2. Set database.yml with your info (we're using postgresql)
3. navigate to server after app is online and enter in an ftp server /settings
4. navigate to /downloaders and enter in some info
  1. you need a leading slash (/) on the FTP file path


# App Config

in settings, the WO Mount Path should point to where your network drive is mounted somethink like /mnt/wo_files, this is the final location files are copied to. 
The Downloader temporarily saves files in /public/downloads (relative to the app itself)

# ToDo

- [ ] Store password in not plain text
- [ ] add a real logging system
- [ ]
