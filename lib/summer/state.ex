defmodule Summer.State do
  use GenServer

  @max_rules 5
  @rules [
    :rule1,
    :rule2,
    :rule3,
    :rule4,
    :rule5,
    :rule6,
    :rule7,
    :rule8,
    :rule9,
    :rule10
  ]

  defstruct active_rules: []

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %__MODULE__{}, name: __MODULE__)
  end

  def init(state) do
    {new_state, _new_rule} = init_rules(state)

    {:ok, new_state}
  end

  def gen_random_rule do
    GenServer.call(__MODULE__, :gen_random_rule)
  end

  def get_stored_random_rules do
    GenServer.call(__MODULE__, :get_active_rules)
  end

  def handle_call(:gen_random_rule, _from, state) do
    {new_state, new_rule} = 
      if can_gen_rule?(state),
        do: init_rules(state),
        else: {state, nil}

    {:reply, new_rule, new_state}
  end

  def handle_call(:get_active_rules, _from, state) do
    active_rules = state.active_rules

    {:reply, active_rules, state}
  end

  defp init_rules(state) do
    active_rules = state.active_rules

    new_rule =
      @rules
      |> Enum.reject(fn rule -> rule in active_rules end)
      |> Enum.random()

    new_state =
      Map.put(state, :active_rules, [new_rule | active_rules])

    {new_state, new_rule}
  end

  defp can_gen_rule?(state) do
    length = length(state.active_rules)

    if length < @max_rules,
      do: true,
      else: false
  end
end
