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

        # Marcador para ver se o carrinho esta abandonado
        

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
      # CODIGO JA PRONTO
      # Pega todos os names que sao duplicados e deixa so um de cada duplicado
      duplicados = Product.group(:name).having("COUNT(name) > 1").pluck(:name)

      # Pra cada duplicado que no caso era CopoStanley e XiaomiPoco
      resultado = duplicados.each do |name|
        # Ele pesquisa no banco de dados todos com o nome CopoStanley e XiaomiPoco
        produtos = Product.where(name: name)

        # E entao relaciona cada um com o CartItem, nessa pesquisa ele extrai o id de cada produto da pesquisa acima
        # E na pesquisa retorna o id de cada produto na tabela CartItem, e ele so pega e soma todos os campos quantity
        # de cada registro e retorna o JSON com o name e o total quantity de cada name duplicado
        total_quantity = CartItem.where(product_id: produtos).sum(:quantity)
        product_price = Product.where(price: produtos)
        product = Product.find_by(name: name)
      
        # Criacao de params para novo registro que vai subsituir todos os duplicados com a soma dos quantitys
        params = {
          name: product.name,
          price: product.price,
          total_price: product.price * total_quantity
        }

        @permanente_product = Product.new(params)
        if @permanente_product.save
          # Pega o id dos produtos duplicados e busca na tabela CartItem e remove
          products_id = Product.where(id: produtos)
          cart_item = CartItem.where(product_id: products_id).destroy_all

          # guarda na variavel o permanente_product e apaga todo o resto
          last_record = produtos.last
          # Product.where.not(id: last_record.id).destroy_all

          # Cria e salva o novo CartItem para cada duplicata com o quantity atualizado tambem
          permanente_cart_item = CartItem.create({
            cart_id: cart.id,
            product_id: @permanente_product.id,
            quantity: total_quantity
          })
          permanente_cart_item.save
        end
      end

      tot_products = Product.all
      tot_price = Product.all.sum(:total_price)
    
      #   # Se o produto nao for salvo, retorna o erro
      #   render json: @product.errors, status: :unprocessable_entity
      # end

      # CODIGO QUE EU FIZ 90%
      # product = cart.products
        
      # duplicados = product.group(:name).having("COUNT(name) > 1").pluck(:name)
      # products_duplicates = Product.where(name: duplicados).to_a
      # count_duplicados = products_duplicates.count
      # quantity = cart.cart_items.sum(:quantity)

      # array = []
      # array_uniq = []
      # array_products = []

      # # Tornando o products_duplicates apenas com um registro representando todos os seus outros duplicados
      # # Adicionando apenas 1 de cada no array_uniq
      # products_duplicates.each do |cada|   
      #   array.push(cada.name)
      #   array_uniq = array.uniq
      # end

      # contando_quantity = []
      # resultado = []

      # # Faz um each para buscar registros duplicados de cada name do array_uniq
      # array_uniq.each do |produc|
      #   grupo = { name: produc, result: Product.where(name: produc).to_a }
      #   # Adiciona o obejto grupo com os nomes buscados no banco de cada produc ao array contando_quantity
      #   contando_quantity << grupo
        
      #   # Esse bloco faz para cada item e soma o quantity, e depois soma cada valor gerado pelo bloco
      #   soma = grupo[:result].sum do |product|
      #     product.cart_items.sum(:quantity)
      #   end

      #   resultado << {
      #     name: grupo[:name],
      #     total: soma
      #   }
      # end

      render json: { products: Product.all, total_price: tot_price }, status: :ok
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
