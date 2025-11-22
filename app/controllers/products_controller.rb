class ProductsController < ApplicationController
  before_action :set_product, only: %i[ show update destroy ]

  # GET /products
  def index
    @products = Product.all

    render json: @products
  end

  # GET /products/1
  def show
    render json: @product
  end

  # NEW /products
  def new 
    @product = Product.new
  end

  # POST /products
  def create
    if product_params.present?
      @product = Product.new(product_params)
    else
      return render json: { error: "Parâmetros inválidos" }, status: :bad_request
    end

    if @product.save
      render json: @product, status: :created, location: @product
    else
      render json: @product.errors, status: :unprocessable_entity
    end
  end

  def show_cart
    unless product_params.present?
      render json: { error: "Parâmetros do produto ausentes" }, status: :bad_request
    else
      cart = Cart.find_by(id: session[:cart_id])
      product = Product.find_by(id: product_params[:id])
  

      render json: { cart: cart, product: product }
      product = Product.new(product_params)

      if product.save
        cart_item = CartItem.create({
          cart_id: cart.id,
          product_id: product.id,
          quantity: 1,
        })
        cart.save
      end 
    end
  end

  # PATCH/PUT /products/1
  def update
    if @product.update(product_params)
      render json: @product
    else
      render json: @product.errors, status: :unprocessable_entity
    end
  end

  # DELETE /products/1
  def destroy
    @product.destroy!
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_product
      @product = Product.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def product_params
      params.require(:product).permit(:name, :price)
    end
end
