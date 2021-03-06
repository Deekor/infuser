# Infuser

A cleaner Ruby wrapper for the InfusionSoft API.

This gem is for use with the Infusionsoft OAuth2 API. If you are using the token-based API, see [Nathan Levitt's gem](https://github.com/nateleavitt/infusionsoft), which this gem is based on.

## Philosophy

Infusionsoft has quite the annoying API. One example: field names are not standardized. Another: some API calls require specific arguments in a specific order, others take a hash.

I've gone out of my way to standardize these things behind the scenes in order to provide a cleaner, Ruby-esque way of dealing with the API.

## Caveats

I developed this gem as part of a project for a client. It covers companies, contacts, and invoices, but not much else, as that was all the client required. Pull requests are always welcome.

## Installation
1. Add the gem to your gemfile.

```
gem install infuser
```

2. Create an initializer file in your Rails app, with your Infusionsoft API settings:

```ruby
Infuser::Configuration.configure do |config|
  config.api_key    = 'Your-App-API-Key'
  config.api_secret = 'Your-App-API-Secret'
end
```

Within the configuration block above, you can also set the `logger` as well as `retry_count` for how many times a call should be attempted before giving up.

## Usage

This gem is for use with Infusionsoft's *OAuth2* API, not the token-based API.

Use the [omniauth-infusionsoft](https://github.com/l1h3r/omniauth-infusionsoft) gem to allow your users to connect and authorize their accounts, just like you would connect [any other OAuth gem](http://railscasts.com/episodes/360-facebook-authentication).

Once a user authorizes their account, Infusionsoft returns an `access_token`. You use this `access_token` to begin using this Infuser gem.

#### General Structure

All models work the same way, and are as close to ActiveRecord as possible. Here is an example with Contacts.

```ruby
client = Infuser::Client.new(access-token)

# retrieve contacts
client.contacts.all

# find a contact
client.contacts.find(1)

# search for a contact
client.contacts.find_by(first_name: 'David', last_name: 'Lesches')

# initialize a contact without saving it
client.contacts.build(first_name: 'David', last_name: 'Lesches')

# create a new contact
client.contacts.create(first_name: 'David', last_name: 'Lesches')

# update a contact
contact = client.contacts.find(1)
contact.first_name = 'John'
contact.save

# get a contact's attributes as a hash
contact = client.contacts.find(1)
contact.attributes

# delete a contact
contact = client.contacts.find(1)
contact.destroy
```

#### Contacts

Complete field list: `:first_name, :middle_name, :nickname, :last_name, :suffix, :title, :company_id, :job_title, :assistant_name, :assistant_phone, :contact_notes, :contact_type, :referral_code, :spouse_name, :username, :website, :date_created, :last_updated`

A contact can also have many phones, faxes, emails, and addresses. A contact can belong to a company.

#### Companies

Complete field list: `:company, :website, :date_created, :last_updated`. Note that the "name" field for a company is called 'company'. Infusionsoft :)

A contact can also have many phones, faxes, emails, and addresses.

You can also assign a contact to a company:

```ruby
client = Infuser::Client.new(access-token)
company = client.companies.find(1)
contact = client.contacts.find(1)
contact.company = company # => assigns and saves company 1 to contact
contact.company # => retrieves company 1

company.contacts # => get all contacts for this company
```

#### Addresses

Both Companies and Contacts have many addresses.

```ruby
# See all addresses for this contact
contact.addresses

# Add an address to this contact
contact.addresses << Infuser::Address.new(street_address: '123 Broadway')
contact.save

# Remove an address from this contact
address = contact.addresses.find(1)
contact.addresses.remove(address)
contact.save
```

Complete field list: `:street_address, :street_address2, :address_type, :city, :state, :country, :postal_code, :zip`

#### Phones

Both Companies and Contacts have many phones.

```ruby
# See all phones for this contact
contact.phones

# Add a phone to this contact
contact.phones << Infuser::Phone.new(number: '1-222-333-4444')
contact.save

# Remove a phone from this contact
phone = contact.phones.find(1)
contact.phones.remove(phone)
contact.save
```

Complete field list: `:number, :extension, :type`

#### Faxes

Both Companies and Contacts have many faxes.

```ruby
# See all faxes for this contact
contact.faxes

# Add a fax to this contact
contact.faxes << Infuser::Fax.new(number: '1-222-333-4444')
contact.save

# Remove a fax from this contact
fax = contact.faxes.find(1)
contact.faxes.remove(fax)
contact.save
```

Complete field list: `:number, :extension, :type`

#### Emails

Both Companies and Contacts have many emails.

```ruby
# See all emails for this contact
contact.emails

# Add an email to this contact
contact.emails << Infuser::Email.new(email: 'info@google.com')
contact.save

# Remove an email from this contact
email = contact.emails.find(1)
contact.emails.remove(email)
contact.save
```

Complete field list: `:email`

#### Invoices

Because Infusionsoft is awesome, creating invoices requires specific parameters in exact order.

```ruby
# 1: contact_id
# 2: description
# 3: date
# 4: lead_affiliate_id (0 should be used if none)
# 5: sale_affiliate_id (0 should be used if none)

client.invoices.create(1, "A test invoice", Time.zone.now.to_date, 0, 0)
```

Once an invoice is created, you can add items to it. These too require specific parameters in exact order.
```ruby
# 1: product_id
# 2: type (UNKNOWN = 0, SHIPPING = 1, TAX = 2, SERVICE = 3, PRODUCT = 4, UPSELL = 5, FINANCECHARGE = 6, SPECIAL = 7)
# 3: price
# 4: quantity
# 5: description
# 6: notes

invoice.add_item(0, 4, 10.00, 3, 'Lollipop Consulting', '')
```

Complete field list when reading fields from an invoice: `:affiliate_id, :contact_id, :credit_status, :date_created, :description, :invoice_total, :invoice_type, :job_id, :lead_affiliate_id, :pay_plan_status, :pay_status, :product_sold,
:promo_code, :refund_status, :synced, :total_due, :total_paid`

#### InvoiceItems

An invoice item is a line item on an invoice. Usage: `invoice.invoice_items`

To add an invoice item, see the Invoices section above. Complete field list when reading: `:commission_status, :date_created, :description, :discount, :invoice_amt, :invoice_id, :order_item_id`

Every invoice item belongs to an order item. These are created automatically by Infusionsoft when adding an invoice item. Order item contains quantity and price per unit information. Usage: `invoice.invoice_items.first.order_item`

Complete field list of order items: `:item_description, :item_name, :item_type, :notes, :order_id, :product_id, :cpu, :ppu, :qty`

## Refreshing Tokens

Infusionsoft access tokens expire after a few hours. You can get a new one using Infuser if you have stored the **refresh\_token**. Every time you sign in to Infusionsoft, you get both an access\_token and a refresh\_token. The access\_token is what you use to retrieve data. Once it expires, you use the refresh\_token to get a new access\_token and refresh\_token.

```ruby
r = Infuser::TokenRefresher.new(refresh-token)
r.refresh
```

## Issues
Submit the issue on Github. I handle gems in my spare time, so if something is time sensitive, be prepared to fork. Pull requests appreciated.

## Copyright
Copyright (c) 2014 David Lesches.

Original based on code from [Nathan Levitt's gem](https://github.com/nateleavitt/infusionsoft).

## License
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.