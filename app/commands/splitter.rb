require './app/foundation.rb'

date, amount, memo, csv_filename = *ARGV[0...4]
tax_rate = 1.0975

csv_text = File.read("#{csv_filename}")
csv = CSV.parse(csv_text, headers: true)

subtxns = csv.map do |row|
  row['amount'] = row['amount'].to_f
  taxable = row['tax'] == 'yes'
  final_amount = taxable ? row['amount'] * tax_rate : row['amount']
  YNAB::SaveSubTransaction.new(
    amount: (final_amount*1000).to_i,
    category_id: category_id(row['category']),
    memo: row['memo']
  )
end

txn = YNAB::SaveTransaction.new(
  account_id: ACCOUNT_IDS[:chime][:checking],
  date: date,
  amount:(amount.to_f*1000).to_i,
  subtransactions: subtxns
)

txns_wrapper = YNAB::SaveTransactionsWrapper.new(transaction: txn)

ynab_api.transactions.create_transaction(MAIN_BUDGET_ID, txns_wrapper)
create_roundup_transfer(txn)
