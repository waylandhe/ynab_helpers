require './environment.rb'

require 'csv'
require 'ynab'

require 'pry'

MAIN_BUDGET_ID = '0bd34749-fb6a-4c31-8c18-6bea2605165a'
ACCOUNT_IDS = {
  chime: {
    checking: '0eed540f-74a2-4fd0-b91e-2bbaa6ec939f'
  }
}
TRANSFER_PAYEES = {
  chime: {
    savings: '27b3c9c8-94bb-4867-ab09-4d1d266097c4'
  }
}

def ynab_api
  ynab_api = YNAB::API.new(ENV['YNAB_ACCESS_TOKEN'])
end

def category_id(text)
  case text
  when 'fm' then '24033658-7cd1-42ab-9219-3dd1716d5f03'
  when 'fo' then 'efe7b513-659f-4544-8c06-a446fdefd0d6'
  when 'g' then '62c7fd06-ef93-4284-91d3-2692f627e9be' # groceries
  when 'gas' then '0d2c3d01-f165-4f8c-a4f5-9eeea6fff139'
  else nil
  end
end

def roundup_transfer(saved_transaction)
  amount = 1000 - saved_transaction.amount.modulo(1000)

  YNAB::SaveTransaction.new(
    account_id: ACCOUNT_IDS[:chime][:checking],
    payee_id: TRANSFER_PAYEES[:chime][:savings],
    date: saved_transaction.date,
    amount: amount
  )
end

def create_roundup_transfer(saved_transaction)
  if saved_transaction.amount.modulo(1000) == 0
    puts "Info: No Roundup Created"
    return
  end

  roundup_txn_wrapper = YNAB::SaveTransactionsWrapper.new(transaction: roundup_transfer(saved_transaction))
  ynab_api.transactions.create_transaction(MAIN_BUDGET_ID, roundup_txn_wrapper)
end
