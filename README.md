# Summer - 

## Package info
type: :letter | :parcel | :fragile
weight: interger()
destination: :domestic | :eu | :international
shipping_class: :standard | :express | :priority
declared_value: float()
has_fragile_sticker: true | false
has_customs_form: true | false
has_insurance: true | false

## Game Rules
1. Letters must weigh under 500g. (:letter | :parcel | :fragile)
2. International packages require a customs form. (:domestic | : eu | :international)
3. Fragile packages cannot use standard shipping. (:standard | :express | :priority)
4. Parcels over 5000g must use priority shipping. 
5. Declared value over 100€ requires insurance. (declared_value)
6. Fragile packages must have a fragile sticker.(has_fragile_sticker)
7. EU and international packages must use express or priority (destination & shipping_class)
8. Letters cannot have insurance. (type + has_insurance)
9. Standard shipping is only available for domestic packages under 2000g. (shipping_class + destination + weight)
10. Fragile international packages over 1000g must use priority. (destination + weight + shipping_class)



PLAN:
--- Commit 1
- personal introduction
- PDQ expectation (don't use AI)
* understanding syntax and how to read errors (focus on understanding how to read errors not on avoind making them)
- what is mix and interactive shell
- show directory structure
* defmodule and create struct + [data types](https://hexdocs.pm/elixir/1.12/typespecs.html)
* defmodule Logic -> generate_package
* create function validation rules (let's start with first 4 rules)
* float range (use recursion, dif between tail and non-tail)
* accessing data from struct
* validate function (with)
* IO.inspect

--- Commit 2
* update function to match on specific elelements in the struct

TODO: create tests for each chapter so that students can see if their code is fine
