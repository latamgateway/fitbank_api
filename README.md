[![CI](https://github.com/latamgateway/fitbank_api/actions/workflows/ci.yml/badge.svg)](https://github.com/latamgateway/fitbank_api/actions/workflows/ci.yml)

# fitbank_api (WIP)

This is a gem used to wrap the FitBank API in classes for convenience. For more detailed info about the functionality [generate documentation](#generate-documentation)

# Build
```bash
git clone git@github.com:latamgateway/fitbank_api.git
cd fitbank_api
gem build fitbank_api.gemspec
gem install fitbank_api-<version>.gem 
```
## Static type checking
```bash
tapioca init
srb tc
```
## Generate documentation
```bash
yardoc lib
```
Open `doc/index.html` with any browser.

# Tests
Use rspec to run tests. Tests require some [environment variables](#environment-variables).

# Environment variables

 * LATAM_CNPJ - Latam company CNPJ. Use when creating payouts
 * The following describe latam bank information
    * LATAM_BANK_CODE
    * LATAM_BANK_AGENCY (This is reffered as BankBranch in fitbank api)
    * LATAM_BANK_ACCOUNT
    * LATAM_BANK_ACCOUNT_DIGIT
 * FITBANK_KEY - Username for the FitBank API used for authentication
 * FITBANK_SECRET - Password for the FitBank API used for authentication
 * FITBANK_BASE_URL - Base Path to FitBank sandbox environment (for sandbox use https://sandboxapi.fitbank.com.br)
 * MKT_PLACE_ID - ID Generated by FitBank API
 * BUSINESS_UNIT_ID - ID Generated by FitBank API
 * PARTNER_ID - ID Generated by FitBank API
 * LATAM_ZIP_CODE - The zip code of Latam Company. Needed for Payins with dynamic QR code.
 
# Example usage (WIP)
We are still clearing issues with the API currently we're not able to create a succesfull request.
 
```ruby
    # Initialize the credentials for the Latam Company
    credentials = FitBankApi::Entities::Credentials.new(
     cnpj: ENV['SENDER_CNPJ'],
     username: ENV['FITBANK_KEY'],
     password: ENV['FITBANK_SECRET'],
     mkt_place_id: ENV['MKT_PLACE_ID'].to_i,
     business_unit_id: ENV['BUSINESS_UNIT_ID'].to_i,
     partner_id: ENV['PARTNER_ID'].to_i
    )

    # Initialize Latam's bank info
    sender_bank_info = FitBankApi::Entities::BankInfo.new(
     bank_code: '450', # For some reason the sandbox accepts only "450"
     bank_agency: '0001',
     bank_account: '3134806',
     bank_account_digit: '1'
    )

    # Initialize customer's bank info
    receiver_bank_info = FitBankApi::Entities::BankInfo.new(...)

    # Make the payout
    FitBankApi::Pix::Payout.new(
     request_id: '123',
     receiver_bank_info:,
     sender_bank_info:,
     credentials:,
     receiver_name: 'John Doe',
     receiver_document: '240.223.700-76',
     value: 50
    )
```
