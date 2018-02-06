class Transaction < ApplicationRecord
  belongs_to :user
  belongs_to :coin
  
  # Removing this association until app is more complete
  # belongs_to :wallet, optional: true
  
  validates :amount, :quantity, :price_per_coin, numericality: { greater_than: 0 }
  validates :fee, numericality: { greater_than_or_equal_to: 0 }
  
  def transaction_params=(transaction_params)
    @transaction_params = transaction_params
  end
  
end
