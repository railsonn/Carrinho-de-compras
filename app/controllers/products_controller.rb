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


  # Adiciona um produto ao carrinho da sessao e retorna o payload com a lista de produtos do carrinho atualizado
  def show_cart
    # Verifica se os parametros do produto estao presentes
    unless product_params.present?
      render json: { error: "Parâmetros do produto ausentes" }, status: :bad_request
    # Se os parametros estiverem presentes
   else
      # Busca o id do carrinho na sessao e adiciona o produto e cria um registro na tabela cart_items
      cart = Cart.find_by(id: session[:cart_id])
      quantity = params[:quantity] || 1

      # Se o carrinho nao estiver criado e guardado na sessao ele cria e salva carrinho na sessao 
      unless cart
        cart = Cart.create({
          cart_value: 0.0
        })
        session[:cart_id] = cart.id
        cart.save
      end

      @product = Product.new(product_params)
      @product.total_price = (@product.price * quantity)

      if @product.save
        cart_item = CartItem.create({
          cart_id: cart.id,
          product_id: @product.id,
          quantity: quantity
        })
        # Atualiza o valor total do carrinho
        cart.cart_value += @product.total_price
        cart.save

        payload = { id: cart.id, products: cart.products.map { |product| {
           cart_value: cart.cart_value,
            id: product.id,
            name: product.name,
            quantity: cart_item.quantity,
            unit_price: product.price,
            total_price: product.total_price
            }
          }
        }
        render json: payload, status: :ok
      else
      # Se o produto nao for salvo, retorna o erro
        render json: @product.errors, status: :unprocessable_entity
      end
    end
  end

  # Se um produto ja estiver no carrinho, atualiza so a quantidade
  def cart_add_items
    cart = Cart.find_by(id: session[:cart_id])
    unless cart
      render json: { error: "Carrinho nao encontrado" }, status: :not_found
    else 
      product = cart.products

      duplicados = product.group(:name).having("COUNT(name) > 1").pluck(:name)
      products_duplicates = Product.where(name: duplicados)


      quantity = cart.cart_items.sum(:quantity)
      
      render json: { duplicados: duplicados, products_duplicates: products_duplicates, quantity: quantity }, status: :ok
    end
  end


  def remove_cart_item
    cart = Cart.find_by(id: session[:cart_id])
    product = cart.products.find_by(id: params[:product_id])

    unless product
      render json: { error: "Produto nao encontrado no carrinho" }, status: :not_found
    else 
      # Destroy product da tabela CartItem e Product, com id do params[:product_id] 
      # Tirando o total_price do produto removido do cart_value da tabela Cart
      cart_item = product.cart_items.find_by(product_id: product.id)
      cart.cart_value -= product.total_price
      cart.save
      cart_item.destroy
      product.destroy
      
      product = Product.all
      render json: { product: product }, status: :ok
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
