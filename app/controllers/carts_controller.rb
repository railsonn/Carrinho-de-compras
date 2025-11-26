class CartsController < ApplicationController
  ## TODO Escreva a lógica dos carrinhos aqui

  def new
    cart = Cart.new
  end

  def create
    cart = Cart.all
  end

  
  private

  def cart_params 
    params.require(:cart).permit(:cart_value)
  end
end