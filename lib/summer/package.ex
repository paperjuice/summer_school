defmodule Summer.Package do
  @type t :: %__MODULE__{
          type: :letter | :parcel | :fragile,
          weight: pos_integer(),
          destination: :domestic | :eu | :international,
          shipping_class: :standard | :express | :priority,
          declared_value: float(),
          has_customs_form: boolean(),
          has_insurance: boolean(),
          has_fragile_sticker: boolean()
        }

  defstruct [
    :type,
    :weight,
    :destination,
    :shipping_class,
    :declared_value,
    :has_customs_form,
    :has_insurance,
    :has_fragile_sticker
  ]
end
