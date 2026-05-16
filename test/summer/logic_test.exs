defmodule Summer.LogicTest do
  use ExUnit.Case, async: true

  alias Summer.Logic
  alias Summer.Package

  %Package{
    type: :letter,
    weight: 400,
    destination: :international,
    shipping_class: :priority,
    declared_value: 86.3,
    has_customs_form: true,
    has_insurance: true,
    has_fragile_sticker: false
  }

  describe "unhappy validate/1" do
    test "fails rule1" do
      package = %Package{
        type: :letter,
        weight: 500,
        destination: :international,
        shipping_class: :priority,
        declared_value: 86.3,
        has_customs_form: true,
        has_insurance: true,
        has_fragile_sticker: false
      }

      actual = Logic.validate(package)
      assert {:invalid, "Letter weights 500g, max 499g"} = actual
    end

    test "fails rule2" do
      package = %Package{
        type: :letter,
        weight: 400,
        destination: :international,
        shipping_class: :priority,
        declared_value: 86.3,
        has_customs_form: false,
        has_insurance: true,
        has_fragile_sticker: false
      }

      actual = Logic.validate(package)
      assert {:invalid, "Internation requires customs form"} = actual
    end

    test "fails rule3" do
      package = %Package{
        type: :fragile,
        weight: 400,
        destination: :international,
        shipping_class: :standard,
        declared_value: 86.3,
        has_customs_form: true,
        has_insurance: true,
        has_fragile_sticker: false
      }

      actual = Logic.validate(package)
      assert {:invalid, "Fragile can't use standard shipping"} = actual
    end

    test "fails rule4" do
      package =
        %Package{
          type: :parcel,
          weight: 6000,
          destination: :international,
          shipping_class: :priority,
          declared_value: 86.3,
          has_customs_form: true,
          has_insurance: true,
          has_fragile_sticker: false
        }

      actual = Logic.validate(package)
      assert {:invalid, "Parcel over 5000g (6000g) must use priority shipping"} = actual
    end

    test "fails rule5" do
      package =
        %Package{
          type: :letter,
          weight: 400,
          destination: :international,
          shipping_class: :priority,
          declared_value: 186.5,
          has_customs_form: true,
          has_insurance: false,
          has_fragile_sticker: false
        }

      actual = Logic.validate(package)
      assert {:invalid, "insurance required for value over 100$ (186.5)"} = actual
    end

    test "fails rule6" do
      package =
        %Package{
          type: :fragile,
          weight: 400,
          destination: :international,
          shipping_class: :priority,
          declared_value: 86.3,
          has_customs_form: true,
          has_insurance: true,
          has_fragile_sticker: false
        }

      actual = Logic.validate(package)
      assert {:invalid, "missing fragile sticker for fragile package"} = actual
    end

    test "fails rule7" do
      package =
        %Package{
          type: :parcel,
          weight: 400,
          destination: :eu,
          shipping_class: :standard,
          declared_value: 86.3,
          has_customs_form: true,
          has_insurance: true,
          has_fragile_sticker: true
        }

      actual = Logic.validate(package)
      assert {:invalid, "eu has wrong shipping class: standard"} = actual
    end

    test "fails rule8" do
      package =
        %Package{
          type: :letter,
          weight: 400,
          destination: :domestic,
          shipping_class: :standard,
          declared_value: 86.3,
          has_customs_form: true,
          has_insurance: true,
          has_fragile_sticker: false
        }

      actual = Logic.validate(package)
      assert {:invalid, "letters can't have insurance"} = actual
    end

    test "fails rule9" do
      package =
        %Package{
          type: :parcel,
          weight: 2500,
          destination: :domestic,
          shipping_class: :standard,
          declared_value: 86.3,
          has_customs_form: true,
          has_insurance: true,
          has_fragile_sticker: false
        }

      actual = Logic.validate(package)

      assert {:invalid, "standard shipping is only available for domestic package under 2000g"} =
               actual
    end

    test "fails rule10" do
      package =
        %Package{
          type: :fragile,
          weight: 1100,
          destination: :international,
          shipping_class: :express,
          declared_value: 86.3,
          has_customs_form: true,
          has_insurance: true,
          has_fragile_sticker: true
        }

      actual = Logic.validate(package)
      assert {:invalid, "fragile internationle packages over 1000g must use priority"} = actual
    end
  end
end
