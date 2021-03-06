class WalletsController < ApplicationController
  # Authenticate the user has logged in before all actions
  # Set the @wallet object before the action so the form can load properly based on the route
  # Check if the current_user is the user that owns the wallet
  before_action :authenticate_user!, :set_wallet
  before_action :user_is_current_user, only: [:show, :edit, :update, :destroy]
  
  def index
    @wallets = current_user.wallets
  end
  
  def show
    @wallet = Wallet.find(params[:id])
    # @tx = Transaction.find_by(id: @wallet.transactions.last.id)
  end
  
  def new
    @wallet = Wallet.new
    @tx = Transaction.new
  end
  
  def create
    @wallet = current_user.wallets.build(wallet_params)
    
    # Split the coin name
    coin_info = params[:wallet][:coin].split(" ")
    coin_name = coin_info[0...-1].join(" ")
    coin_symbol = coin_info[-1].scan(/\w+(?!\w|\()/)[0]
    coin_price = CryptocompareApi.last_known_value(coin_symbol) if params[:wallet][:coin]
    coin_id = CryptocompareApi.find_coin_id(coin_symbol)
    
    # Find or Create the coin to associate
    @wallet.coin = Coin.find_or_create_by(
                            name: coin_name, 
                            symbol: coin_symbol, 
                            last_known_value: coin_price,
                            id: coin_id)
    
    # Check if the wallet is valid, and the coin is valid
    if @wallet.valid? && @wallet.coin.valid?
      @wallet.coin.save
      @wallet.save
      @tx = Transaction.find_by(wallet_id: @wallet.id)
      @tx.coin = @wallet.coin
      @tx.save
      flash[:success] = "Wallet successfully added!"
      redirect_to user_wallets_path(current_user)
    else
      flash[:alert] = @wallet.errors.full_messages.to_sentence
      redirect_to new_user_wallet_path(current_user)
    end
  end
  
  def update
    @wallet.update(wallet_params)
    
    # Split the coin name
    coin_info = params[:wallet][:coin].split(" ")
    coin_name = coin_info[0...-1].join(" ")
    coin_symbol = coin_info[-1].scan(/\w+(?!\w|\()/)[0]
    coin_price = CryptocompareApi.last_known_value(coin_symbol) if params[:wallet][:coin]
    coin_id = CryptocompareApi.find_coin_id(coin_symbol)

    # Find or Create the coin to associate
    @wallet.coin = Coin.find_or_create_by(
                            name: coin_name, 
                            symbol: coin_symbol, 
                            last_known_value: coin_price,
                            id: coin_id)
    
    # Update the coin info
    @wallet.coin.update(name: coin_name, symbol: coin_symbol, id: coin_id)
    @wallet.coin.update(last_known_value: coin_price) if coin_price
    
    
    if @wallet.valid? && @wallet.user == current_user
      @wallet.coin.save
      @wallet.save
      
      @tx = Transaction.find(@wallet.transactions.last.id)
      @tx.coin = @wallet.coin
      @tx.save
      
      flash[:success] = "Wallet successfully updated!"
      redirect_to user_wallets_path(current_user)
    else
      flash[:alert] = @wallet.errors.full_messages.to_sentence
      # Redirect preserves the visual formatting
      redirect_to user_wallets_path(current_user, @wallet)
    end
  end
  
  def destroy
    @wallet = current_user.wallets.find_by(id: params[:id])
    
    if @wallet.user_id == current_user.id
      flash[:success] = "Wallet deleted!"
      @wallet.destroy 
      redirect_to user_wallets_path(current_user)
    else
      flash[:alert] = "Unauthorized action! The administrator has been notified."
      # Redirect preserves the visual formatting
      redirect_to user_wallet_path(current_user, @wallet)
    end
  end
  
  
  private
  
  def user_is_current_user
    unless current_user.id == params[:user_id].to_i
      flash[:alert] = "You may only view your own wallets."
      redirect_to root_path
    end
  end
  
  def set_wallet
    @wallet = Wallet.find_by(id: params[:id])
  end
  
  def wallet_params
    params.require(:wallet).permit(:name, :coin_amount, :user_deposit, :notes, :user_id, :coin_id, transactions_attributes: [:id, :amount, :quantity, :price_per_coin, :fee, :user_id])
  end
  
end
