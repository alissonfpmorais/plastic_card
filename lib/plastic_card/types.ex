defmodule PlasticCard.Type do
  @moduledoc false

  alias PlasticCard.{Type, Utils}

  defstruct [
    :name,
    :brand,
    :pattern,
    :security_code,
    :test_numbers
  ]

  @type security_code() :: %{name: String.t(), size: pos_integer()}

  @type t() :: %__MODULE__{
          name: String.t(),
          brand: atom(),
          pattern: Regex.t(),
          security_code: security_code(),
          test_numbers: nonempty_list(String.t())
        }

  @spec card_types() :: nonempty_list(Type.t())
  def card_types do
    []
    |> append(
      "American Express",
      :american_express,
      ~r/^3[47][0-9]{13}$/,
      "CID",
      4,
      ~w(378282246310005 371449635398431 378734493671000)
    )
    |> append(
      "Diners Club",
      :diners_club,
      ~r/^3(?:0[0-5]|[68][0-9])[0-9]{11}$/,
      "CVV",
      3,
      ~w(30569309025904 38520000023237)
    )
    |> append(
      "Discover",
      :discover,
      ~r/^6(?:011|5[0-9]{2})[0-9]{12}$/,
      "CID",
      3,
      ~w(6011000990139424 6011111111111117)
    )
    |> append(
      "JCB",
      :jcb,
      ~r/^(?:2131|1800|35\d{3})\d{11}$/,
      "CVV",
      3,
      ~w(3530111333300000 3566002020360505)
    )
    |> append(
      "Maestro",
      :maestro,
      ~r/(^6759[0-9]{2}([0-9]{10})$)|(^6759[0-9]{2}([0-9]{12})$)|(^6759[0-9]{2}([0-9]{13})$)/,
      "CVC",
      3
    )
    |> append(
      "Master Card",
      :master_card,
      ~r/^5[1-5][0-9]{14}$/,
      "CVC",
      3,
      ~w(5555555555554444 5105105105105100)
    )
    |> append("UnionPay", :unionpay, ~r/^62[0-5]\d{13,16}$/, "CVN", 3, ~w(6212341111111111))
    |> append(
      "Visa",
      :visa,
      ~r/^4[0-9]{12}(?:[0-9]{3})?$/,
      "CVV",
      3,
      ~w(4111111111111111 4012888888881881 4222222222222 4005519200000004 4009348888881881 4012000033330026 4012000077777777 4217651111111119 4500600000000061 4000111111111115)
    )
  end

  @spec append(
          list(Type.t()),
          String.t(),
          atom(),
          Regex.t(),
          String.t(),
          pos_integer(),
          list(String.t())
        ) ::
          nonempty_list(Type.t())
  def append(
        types,
        name,
        brand,
        pattern,
        security_code_name,
        security_code_size,
        test_numbers \\ []
      )
      when is_list(types) and
             is_binary(name) and
             is_atom(brand) and
             is_struct(pattern, Regex) and
             is_binary(security_code_name) and
             is_integer(security_code_size) and
             is_list(test_numbers) do
    types ++
      [
        %__MODULE__{
          name: name,
          brand: brand,
          pattern: pattern,
          security_code: %{name: security_code_name, size: security_code_size},
          test_numbers: test_numbers
        }
      ]
  end

  @spec card_type(list(Type.t()), String.t()) :: {:ok, Type.t()} | {:error, :invalid_type}
  def card_type(types \\ Type.card_types(), card_number) do
    card_number = Utils.normalize_text(card_number)

    types
    |> Enum.filter(fn %Type{pattern: pattern} -> String.match?(card_number, pattern) end)
    |> Enum.at(0)
    |> case do
      nil -> {:error, :invalid_type}
      type -> {:ok, type}
    end
  end

  @spec fetch_by_brand(list(Type.t()), atom()) :: {:ok, Type.t()} | {:error, :not_found}
  def fetch_by_brand(types \\ Type.card_types(), brand) when is_list(types) and is_atom(brand) do
    types
    |> Enum.find(fn %Type{brand: brand_type} -> brand_type == brand end)
    |> case do
      nil -> {:error, :not_found}
      type -> {:ok, type}
    end
  end
end
