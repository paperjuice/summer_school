defmodule Summer.State do
  use GenServer

  alias Summer.Player
  alias Summer.Logic

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
            current_game_time: 0,
            players: [],
            # :in_progress | :ended
            game_state: :waiting

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %__MODULE__{}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  def gen_random_rule do
    GenServer.call(__MODULE__, :gen_random_rule)
  end

  def get_stored_random_rules do
    GenServer.call(__MODULE__, :get_active_rules)
  end

  def store_player(name, pid) do
    GenServer.call(__MODULE__, {:store_player, name, pid})
  end

  def update_player_score(pid, package, expected) do
    GenServer.call(__MODULE__, {:update_player_score, pid, package, expected})
  end

  def player_ready(name) do
    GenServer.call(__MODULE__, {:player_ready, name})
  end

  @impl true
  def handle_call({:store_player, name, pid}, _from, state) do
    new_player = %Player{
      name: name,
      pid: pid
    }

    player_list = Map.get(state, :players)
    updated_player_list = [new_player | player_list]
    new_state = Map.put(state, :players, updated_player_list)

    Phoenix.PubSub.broadcast(
      Summer.PubSub,
      "game_room",
      {:update_player_list, updated_player_list}
    )

    {:reply, new_player, new_state}
  end

  @impl true
  def handle_call({:player_ready, name}, _from, state) do
    {[player], remaining_players} =
      Enum.split_with(state.players, fn player -> player.name == name end)

    player_ready = Map.put(player, :ready?, true)
    updated_player_list = [player_ready | remaining_players]
    game_state = maybe_start_game(updated_player_list)

    new_state =
      state
      |> Map.put(:players, updated_player_list)
      |> Map.put(:game_state, game_state)

    Phoenix.PubSub.broadcast(
      Summer.PubSub,
      "game_room",
      {:update_player_list, updated_player_list}
    )

    {:reply, {player_ready, game_state}, new_state}
  end

  @impl true
  def handle_call({:update_player_score, pid, package, expected}, _from, state) do
    player_list = state.players
    active_rules = state.active_rules

    {[player], remaining_players} =
      Enum.split_with(player_list, fn player -> player.pid == pid end)

    {validation_result, validation_msg} =
      Logic.validate(package, active_rules)

    decision =
      if validation_result == expected,
        do: :correct,
        else: :incorrect

    score_modifier =
      if decision == :correct,
        do: 1,
        else: -1

    new_score = max(player.score + score_modifier, 0)

    updated_player = Map.put(player, :score, new_score)

    updated_player_list = [updated_player | remaining_players]

    Phoenix.PubSub.broadcast(
      Summer.PubSub,
      "game_room",
      {:update_player_list, sort_player_list(updated_player_list)}
    )

    new_state = Map.put(state, :players, updated_player_list)

    {:reply, {updated_player, decision, validation_msg}, new_state}
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
      Phoenix.PubSub.broadcast(Summer.PubSub, "game_room", {:game_ended, :ended})
    end

    new_state =
      Map.put(state_with_new_rule, :current_game_time, current_game_time + 1)

    {:noreply, new_state}
  end

  # in seconds
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

  defp sort_player_list(player_list) do
    Enum.sort(player_list, fn p1, p2 -> p1.score > p2.score end)
  end

  defp maybe_start_game(player_list) do
    all_ready? = Enum.all?(player_list, fn player -> player.ready? end)

    if all_ready? do
      # start game tick
      Phoenix.PubSub.broadcast(Summer.PubSub, "game_room", {:game_start, :in_progress})
      Process.send_after(self(), :tick, 1_000)
      :in_progress
    else
      :waiting
    end
  end
end
