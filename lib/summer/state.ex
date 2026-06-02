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

  defstruct active_rules: [],
            current_game_time: 0

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %__MODULE__{}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    # start game tick
    Process.send_after(self(), :tick, 1_000)

    {:ok, state}
  end

  def gen_random_rule do
    GenServer.call(__MODULE__, :gen_random_rule)
  end

  def get_stored_random_rules do
    GenServer.call(__MODULE__, :get_active_rules)
  end

  @impl true
  def handle_call(:gen_random_rule, _from, state) do
    {new_state, new_rule} = do_gen_random_rule(state)

    {:reply, new_rule, new_state}
  end

  def handle_call(:get_active_rules, _from, state) do
    active_rules = state.active_rules

    {:reply, active_rules, state}
  end

  @impl true
  def handle_info(:tick, state) do
    Process.send_after(self(), :tick, 1_000)

    current_game_time = Map.get(state, :current_game_time)
    Phoenix.PubSub.broadcast(Summer.PubSub, "game_room", {:tick_update, current_game_time})

    {state_with_new_rule, _new_rule} =
      if rem(current_game_time, 30) == 0 do
        Phoenix.PubSub.broadcast(Summer.PubSub, "game_room", :update_rules)
        do_gen_random_rule(state)
      else
        {state, nil}
      end

    if current_game_time > max_game_time() do
      Phoenix.PubSub.broadcast(Summer.PubSub, "game_room", :game_ended)
    end

    new_state =
      Map.put(state_with_new_rule, :current_game_time, current_game_time + 1)

    {:noreply, new_state}
  end

  def max_game_time, do: 240

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

  defp do_gen_random_rule(state) do
    if can_gen_rule?(state),
      do: init_rules(state),
      else: {state, nil}
  end
end
