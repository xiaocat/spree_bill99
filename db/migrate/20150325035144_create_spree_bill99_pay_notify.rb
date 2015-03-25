class CreateSpreeBill99PayNotify < ActiveRecord::Migration
  def change
    create_table :spree_bill99_pay_notifies do |t|
      t.string :merchant_acct_id
      t.string :bank_id
      t.string :order_id
      t.string :order_amount
      t.string :deal_id
      t.string :pay_amount
      t.integer :fee
      t.text   :source_data
      t.datetime :created_at
    end
  end
end
