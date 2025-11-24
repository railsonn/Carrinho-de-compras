class CartsController < ApplicationController
  ## TODO Escreva a lógica dos carrinhos aqui

  def new
    cart = Cart.new
  end

  def create
    cart = Cart.find_by(id: session[:cart_id])
    unless cart
      # Nao existe um carrinho na sessao, cria um novo
      cart = Cart.create({
        cart_value: 0.0
      })
      # e salva o id do carrinho na sessao
      session[:cart_id] = cart.id
      render json: cart
    else
      # Carrinho ja existe na sessao, retorna ele
      render json: cart
    end
  end
  
  private

  def cart_params 
    params.require(:cart).permit(:cart_value)
  end
end