require './app/foundation.rb'

logger = Logger.new(STDOUT)
logger.level = Logger::WARN
date, amount, memo, csv_filename, tax_rate = *ARGV[0...5]

tax_rate = 1 + (tax_rate.to_f / 100)


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
  subtransactions: subtxns,
  memo: memo
)

txns_wrapper = YNAB::SaveTransactionsWrapper.new(transaction: txn)
begin
  ynab_api.transactions.create_transaction(MAIN_BUDGET_ID, txns_wrapper)
  create_roundup_transfer(txn)
rescue => exception
  if exception.response_body.include? 'amount must equal the sum of subtransaction amounts'
    subtxns_total = txns_wrapper.transaction.subtransactions.sum(&:amount)
    logger.debug "__ERROR__ #{exception.response_body}"
    logger.debug "__TOTAL__ #{subtxns_total}"
    logger.debug txns_wrapper
    if subtxns_total > txns_wrapper.transaction.amount
      if abs(subtxns_total - txns_wrapper.transaction.amount) > 50
        raise "cent difference is too large... something is fishy. maybe wrong tax rate?"
      else
        cents_to_subtract = (subtxns_total - txns_wrapper.transaction.amount) / 10
        logger.error "cents to subtract: #{cents_to_subtract}"
      end
    else
      raise "subtxns_total < txns_wrapper.transaction.amount"
    end
  else
    logger.fatal "__ERROR__#{exception.response_body}"
    raise
  end
end

