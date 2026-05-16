defmodule Summer.Logic do
  alias Summer.Package

  def generate_package do
    type = Enum.random([:letter, :parcel, :fragile])
    weight = calculate_weight(type)
    destination = Enum.random([:domestic, :eu, :international])
    shipping_class = Enum.random([:standard, :express, :priority])
    declared_value = Enum.random(float_range())
    has_fragile_sticker = Enum.random([true, false])
    has_customs_form = Enum.random([true, false])
    has_insurance = Enum.random([true, false])

    %Package{
      type: type,
      weight: weight,
      destination: destination,
      shipping_class: shipping_class,
      declared_value: declared_value,
      has_fragile_sticker: has_fragile_sticker,
      has_customs_form: has_customs_form,
      has_insurance: has_insurance
    }
  end

  def validate_rule1(:letter, weight) do
    if weight < 500 do
      {:valid, "rule1"}
    else
      {:invalid, "Letter weights #{weight}g, max 499g"}
    end
  end

  def validate_rule1(_type, _weight), do: :valid

  def validate_rule2(:international, true), do: {:valid, "rule2"}
  def validate_rule2(:international, false), do: {:invalid, "Internation requires customs form"}
  def validate_rule2(_destination, _has_customs_form), do: :valid

  def validate_rule3(:fragile, :standard), do: {:invalid, "Fragile can't use standard shipping"}
  def validate_rule3(_type, _destination), do: {:valid, "rule3"}

  def validate_rule4(:parcel, weight, :priority) do
    if weight < 5000 do
      {:valid, "rule4"}
    else
      {:invalid, "Parcel over 5000g #{weight} must use priority shipping"}
    end
  end

  def validate_rule4(_type, _weight, _shipping_class), do: {:valid, "rule4"}

  def validate_rule5(declared_value, true) do
    if declared_value <= 100 do
      {:valid, "rule5"}
    else
      {:invalid, "insurance required for value over 100$ (#{declared_value})"}
    end
  end

  def validate_rule5(_declared_value, false), do: {:valid, "rule5"}

  def validate_rule6(:fragile, true), do: {:valid, "rule6"}

  def validate_rule6(:fragile, false),
    do: {:invalid, "missing fragile sticker for fragile package"}

  def validate_rule6(_type, _has_fragile_sticker), do: :valid

  def validate_rule7(:eu, shipping_class) when shipping_class in [:express, :priority],
    do: {:valid, "rule7"}

  def validate_rule7(:international, shipping_class)
      when shipping_class in [:express, :priority],
      do: {:valid, "rule7"}

  def validate_rule7(destination, shipping_class) when destination in [:eu, :international],
    do: {:invalid, "#{destination} has wrong shipping class: #{shipping_class}"}

  def validate_rule7(_destination, _shipping_class), do: {:valid, "rule7"}

  def validate_rule8(:letter, true), do: {:invalid, "letters can't have insurance"}
  def validate_rule8(_type, _has_insurance), do: {:valid, "rule8"}

  def validate_rule9(:standard, :domestic, weight) do
    if weight < 2000 do
      {:valid, "rule9"}
    else
      {:invalid, "standard shipping is only available for domestic package under 2000g"}
    end
  end

  def validate_rule9(_shipping_class, _destination, _weight), do: {:valid, "rule9"}

  def validate_rule10(:fragile, :international, :priority, weight) do
    if weight > 1000,
      do: {:valid, "rule10"},
      else: {:invalid, "fragile internationla priority packages must be under 1000g"}
  end

  def validate_rule10(:fragile, :international, _shipping_class, _weight) do
    {:invalid, "fragile internationla must be priority"}
  end

  def validate_rule10(type, destination, shipping_class, weight) do
    {:valid, "rule10"}
  end

  def float_range do
    10..2000
    |> Range.to_list()
    |> build_float_range([])
    |> Enum.reverse()
  end

  defp build_float_range([], acc), do: acc

  defp build_float_range([hd | tl], acc) do
    to_float = hd / 10
    new_acc = [to_float | acc]

    build_float_range(tl, new_acc)
  end

  defp calculate_weight(:letter), do: Enum.random(1..999)
  defp calculate_weight(_), do: Enum.random(1..10000)
end
