class TovsController < ApplicationController
  before_action :set_tov, only: [:show, :edit, :update, :destroy]
  # before_action :authorize

  # GET /tovs
  # GET /tovs.json
  def index
    @search = Tov.ransack(params[:q]) #используется gem ransack для поиска и сортировки
    @search.sorts = 'id asc' if @search.sorts.empty? # сортировка таблицы по алфавиту по умолчанию
    @tovs = @search.result.paginate(page: params[:page], per_page: 100)
    @tov_all = Tov.all.order(:id)#.limit(10)#.where.not(:insid => nil).order(:id)
    if params['file_type'] == 'redir'
      filename = "insales_redir.xls"
      respond_to do |format|
        format.html
        format.xls { headers["Content-Disposition"] = "attachment; filename=\"#{filename}\"" }
        format.json
        format.xml
      end
    else
      filename = "insales.csv"
      respond_to do |format|
        format.html
        format.csv { headers["Content-Disposition"] = "attachment; filename=\"#{filename}\"" }
        format.json
        format.xml
      end
    end
  end

  def create_csv_with_params
    Services::CreateCsvWithParams.call
    redirect_to tovs_path, notice: "CREATE CSV WITH PARAMS OK"
  end

  def csv_param
    Tov.csv_param
    flash[:notice] = "Запустили"
    redirect_to tovs_path
  end

  # GET /tovs/1
  # GET /tovs/1.json
  def show
  end

  # GET /tovs/new
  def new
    @tov = Tov.new
  end

  # GET /tovs/1/edit
  def edit
  end

  # POST /tovs
  # POST /tovs.json
  def create
    @tov = Tov.new(tov_params)

    respond_to do |format|
      if @tov.save
        format.html { redirect_to @tov, notice: 'Tov was successfully created.' }
        format.json { render :show, status: :created, location: @tov }
      else
        format.html { render :new }
        format.json { render json: @tov.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /tovs/1
  # PATCH/PUT /tovs/1.json
  def update
    respond_to do |format|
      if @tov.update(tov_params)
        format.html { redirect_to @tov, notice: 'Tov was successfully updated.' }
        format.json {head :no_content }#{ render :show, status: :ok, location: @tov }
      else
        format.html { render :edit }
        format.json { render json: @tov.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /tovs/1
  # DELETE /tovs/1.json
  def destroy
    @tov.destroy
    respond_to do |format|
      format.html { redirect_to tovs_url, notice: 'Tov was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def download
    @tov = Tov.download
    flash[:notice] = 'Products was successfully updated'
    redirect_to tovs_path
  end

  def import
    Tov.import(params[:file])
    flash[:notice] = 'Products was successfully import'
    redirect_to tovs_path
  end

  def xml
    @tovs = Tov.where(:check => [true] ).order(:id).limit(1000) #Tov.where("cat2" => "Комплектующие для сантехники")
    respond_to do |format|
      format.xml
    end
  end

  def delete_selected
    puts params[:ids]
    @tovs = Tov.find(params[:ids])
    @tovs.each do |item|
      item.destroy
    end
    respond_to do |format|
      format.html { redirect_to tovs_url, notice: 'Записи удалёны' }
      format.json { render json: {:status => "ok", :message => "Записи удалёны"} }
    end
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_tov
    @tov = Tov.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def tov_params
    params.require(:tov).permit(:fid, :link, :title, :desc, :price, :pict, :cat, :p1, :p2, :p3, :linkins, :cat1, :oldprice, :p4, :insid, :mtitle, :mdesc, :mkeyw, :sku, :check, :sdesc, :cat2, :cat3)
  end
end
