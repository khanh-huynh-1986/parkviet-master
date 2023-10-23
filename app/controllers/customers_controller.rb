class CustomersController < ApplicationController
  before_action :set_customer, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_user!

  def index
    respond_to do |format|
      format.html {
        unless has_permission?("customer_view")
          render "roles/no_permission", layout: 'home'
          return
        end

        @per_page = params[:per_page] || Product.per_page || 20
        @q = Customer.ransack(params[:q])
        @customers = @q.result.by_store(current_store.id).paginate(:page => params[:page], :per_page => @per_page)
      }
      format.json {
        @q = Customer.ransack(params[:q])
        @customers = @q.result.by_store(current_store.id)
        render json: @customers, each_serializer: CustomerSerializer
      }
    end
  end

  def show
    unless has_permission?("customer_view")
      render "roles/no_permission", layout: 'home'
      return
    end
  end

  def new
    unless has_permission?("customer_new")
      render "roles/no_permission", layout: 'home'
      return
    end

    @customer = Customer.new
  end

  def edit
    unless has_permission?("customer_edit")
      render "roles/no_permission", layout: 'home'
    end
  end

  def search
    term = params[:query]
    @customers = CustomersIndex.query{match name: term}.or.query{match code: term}
  end

  def create
    @customer = Customer.new(customer_params)
    @customer.birthday = build_birthday(params)
    @customer.user = current_user
    @customer.store = current_store
    @customer.abbr_name = @customer.name.to_s.split.map(&:first).join.downcase
    if @customer.save
      @customer.code = build_customer_code unless @customer.code.present?
      @customer.save
      redirect_to customers_path, notice: t(:notice_create_customer_successfully)
    end
  end

  def update
    @customer.code = build_customer_code unless params[:customer][:code].present?
    @customer.birthday = build_birthday(params)
    if @customer.update(customer_params)
      redirect_to customers_path, notice: t(:notice_update_customer_successfully)
    end
  end

  def destroy
    unless has_permission?("customer_delete")
      render "roles/no_permission", layout: 'home'
      return
    end

    @customer.status = :archived
    if @customer.save
      redirect_to customers_path
    end
  end

  private
  def build_customer_code
    "KH"+ @customer.id.to_s.rjust(6, '0')
  end

  def build_birthday(params)
    if params[:customer]["birthday(1i)"].present? && params[:customer]["birthday(2i)"].present? && params[:customer]["birthday(3i)"].present?
      Date.new(params[:customer]["birthday(1i)"].to_i,params[:customer]["birthday(2i)"].to_i,params[:customer]["birthday(3i)"].to_i)
    end
  end

  def set_customer
    @customer = Customer.find(params[:id])
  end

  def customer_params
    params.require(:customer).permit(:name, :customer_type, :code, :phone, :email, :birthday, :sex, :company_name, :address, :province_id, :district_id, :commune_id, :tax, :description)
  end
end
