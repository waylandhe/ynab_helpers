require './app/foundation.rb'
require 'fuzzy_match'

date, payee, amount, category, memo = *ARGV[0...4]
tax_rate = 1.0975




txn = YNAB::SaveTransaction.new(
  account_id: ACCOUNT_IDS[:chime][:checking],
  payee_name: '',
  date: date,
  amount:(amount.to_f*1000).to_i,
  category_id: category_id(category),
  memo: memo
)

txns_wrapper = YNAB::SaveTransactionsWrapper.new(transaction: txn)

ynab_api.transactions.create_transaction(MAIN_BUDGET_ID, txns_wrapper)
create_roundup_transfer(txn)
