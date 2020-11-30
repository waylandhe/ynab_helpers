require './app/foundation.rb'

date, amount, memo, csv_filename = *ARGV[0...4]
tax_rate = 1.0925

csv_text = File.read("#{csv_filename}")
csv = CSV.parse(csv_text, headers: true)

subtxns = csv.map do |row|
  row['amount'] = row['amount'].to_f
  taxable = row['tax'] == 'yes'
  final_amount = if taxable
                   sprintf('%.2f', row['amount'] * tax_rate).to_f
                 else
                   row['amount']
                 end
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
begin
  ynab_api.transactions.create_transaction(MAIN_BUDGET_ID, txns_wrapper)
  create_roundup_transfer(txn)
rescue => exception
  if exception.response_body.include? 'amount must equal the sum of subtransaction amounts'
    puts "__TOTAL__#{txns_wrapper.transaction.subtransactions.sum(&:amount)}"
    pp txns_wrapper
    raise
  else
    puts "__ERROR__#{exception.response_body}"
    raise
  end
end

