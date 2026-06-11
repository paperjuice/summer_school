defmodule Summer.State do
  use GenServer

  alias Summer.Player
  alias Summer.Logic

  @game_room_topic "game_room"

  @tick_interval_ms 1_000
  @max_game_time_seconds 240
  @rule_rotation_interval_seconds 30

  @points_for_correct 1
  @penalty_for_incorrect -1
  @min_score 0

  @max_active_rules 5
  @available_rules [
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

  @type game_state :: :waiting | :in_progress | :ended

  @type t :: %__MODULE__{
          active_rules: [atom()],
          current_game_time: non_neg_integer(),
          players: [Player.t()],
          game_state: game_state()
        }

  defstruct active_rules: [],
            current_game_time: 0,
            players: [],
            game_state: :waiting

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %__MODULE__{}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  def activate_random_rule do
    GenServer.call(__MODULE__, :activate_random_rule)
  end

  def get_active_rules do
    GenServer.call(__MODULE__, :get_active_rules)
  end

  def add_player(name, pid) do
    GenServer.call(__MODULE__, {:add_player, name, pid})
  end

  def update_player_score(pid, package, expected) do
    GenServer.call(__MODULE__, {:update_player_score, pid, package, expected})
  end

  @spec player_ready(String.t()) :: {Player.t(), game_state()}
  def player_ready(name) do
    GenServer.call(__MODULE__, {:player_ready, name})
  end

  # in seconds
  def max_game_time, do: @max_game_time_seconds

  @impl true
  def handle_call({:add_player, name, pid}, _from, state) do
    new_player = %Player{
      name: name,
      pid: pid
    }

    updated_player_list = [new_player | state.players]
    new_state = Map.put(state, :players, updated_player_list)

    broadcast({:update_player_list, updated_player_list})

    {:reply, new_player, new_state}
  end

  @impl true
  def handle_call({:player_ready, name}, _from, state) do
    {[player], remaining_players} =
      Enum.split_with(state.players, fn player -> player.name == name end)

    readied_player = Map.put(player, :ready?, true)
    updated_player_list = [readied_player | remaining_players]
    game_state = maybe_start_game(updated_player_list)

    new_state =
      state
      |> Map.put(:players, updated_player_list)
      |> Map.put(:game_state, game_state)

    broadcast({:update_player_list, updated_player_list})

    {:reply, {readied_player, game_state}, new_state}
  end

  @impl true
  def handle_call({:update_player_score, pid, package, expected}, _from, state) do
    {[player], remaining_players} =
      Enum.split_with(state.players, fn player -> player.pid == pid end)

    {validation_result, validation_msg} =
      Logic.validate(package, state.active_rules)

    decision =
      if validation_result == expected,
        do: :correct,
        else: :incorrect

    score_delta =
      if decision == :correct,
        do: @points_for_correct,
        else: @penalty_for_incorrect

    new_score = max(player.score + score_delta, @min_score)

    updated_player = Map.put(player, :score, new_score)

    updated_player_list = [updated_player | remaining_players]

    broadcast({:update_player_list, sort_by_score(updated_player_list)})

    new_state = Map.put(state, :players, updated_player_list)

    {:reply, {updated_player, decision, validation_msg}, new_state}
  end

  @impl true
  def handle_call(:activate_random_rule, _from, state) do
    {new_state, new_rule} = maybe_activate_random_rule(state)

    {:reply, new_rule, new_state}
  end

  def handle_call(:get_active_rules, _from, state) do
    {:reply, state.active_rules, state}
  end

  @impl true
  def handle_info(:tick, state) do
    schedule_tick()

    current_game_time = state.current_game_time
    broadcast({:tick_update, current_game_time})

    {state_with_new_rule, _new_rule} =
      if rem(current_game_time, @rule_rotation_interval_seconds) == 0 do
        broadcast(:update_rules)
        maybe_activate_random_rule(state)
      else
        {state, nil}
      end

    if current_game_time > max_game_time() do
      broadcast({:game_ended, :ended})
    end

    new_state =
      Map.put(state_with_new_rule, :current_game_time, current_game_time + 1)

    {:noreply, new_state}
  end

  defp schedule_tick do
    Process.send_after(self(), :tick, @tick_interval_ms)
  end

  defp broadcast(message) do
    Phoenix.PubSub.broadcast(Summer.PubSub, @game_room_topic, message)
  end

  defp activate_new_rule(state) do
    active_rules = state.active_rules

    new_rule =
      @available_rules
      |> Enum.reject(fn rule -> rule in active_rules end)
      |> Enum.random()

    new_state =
      Map.put(state, :active_rules, [new_rule | active_rules])

    {new_state, new_rule}
  end

  defp can_activate_rule?(state) do
    length(state.active_rules) < @max_active_rules
  end

  defp maybe_activate_random_rule(state) do
    if can_activate_rule?(state),
      do: activate_new_rule(state),
      else: {state, nil}
  end

  defp sort_by_score(player_list) do
    Enum.sort(player_list, fn p1, p2 -> p1.score > p2.score end)
  end

  @spec maybe_start_game([Player.t()]) :: game_state()
  defp maybe_start_game(player_list) do
    all_ready? = Enum.all?(player_list, fn player -> player.ready? end)

    if all_ready? do
      broadcast({:game_start, :in_progress})
      schedule_tick()
      :in_progress
    else
      :waiting
    end
  end
end
