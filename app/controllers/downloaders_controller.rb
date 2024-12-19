class DownloadersController < ApplicationController
  before_action :set_downloader, only: %i[ show edit update destroy ]

  # GET /downloaders or /downloaders.json
  def index
    @downloaders = Downloader.all
  end

  # GET /downloaders/1 or /downloaders/1.json
  def show
  end

  # GET /downloaders/new
  def new
    @downloader = Downloader.new
  end

  # GET /downloaders/1/edit
  def edit
  end

  # POST /downloaders or /downloaders.json
  def create
    @downloader = Downloader.new(downloader_params)

    respond_to do |format|
      if @downloader.save
        format.html { redirect_to @downloader, notice: "Downloader was successfully created." }
        format.json { render :show, status: :created, location: @downloader }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @downloader.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /downloaders/1 or /downloaders/1.json
  def update
    respond_to do |format|
      if @downloader.update(downloader_params)
        format.html { redirect_to @downloader, notice: "Downloader was successfully updated." }
        format.json { render :show, status: :ok, location: @downloader }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @downloader.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /downloaders/1 or /downloaders/1.json
  def destroy
    @downloader.destroy
    respond_to do |format|
      format.html { redirect_to downloaders_url, notice: "Downloader was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  def start_job
    logger.info "Maunal download triggered from web interface"
    redirect_back fallback_location: '/', notice: "Download Triggerd"
    ManualDownloadJob.perform_later(params[:id])
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_downloader
      @downloader = Downloader.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def downloader_params
      params.require(:downloader).permit(:ftp_path, :rename, :rename_prefix, :setting_id, :interval, :processing_status, :backup, :backup_path)
    end
end
