defmodule SummerWeb.MainLive do
  use SummerWeb, :live_view

  alias Summer.Logic
  alias Summer.State

  import SummerWeb.GameComponents

  @time_to_respond 1_000

  @impl true
  def mount(_params, _session, socket) do
    Phoenix.PubSub.subscribe(Summer.PubSub, "game_room")

    package = Logic.generate_package()
    timestamp = DateTime.utc_now() |> DateTime.to_unix()

    active_rules = State.get_stored_random_rules()
    rule_descriptions = Logic.descriptions_by_rules(active_rules)

    new_socket =
      socket
      |> assign(:package, package)
      |> assign(:score, 0)
      |> assign(:timestamp, timestamp)
      |> assign(:validation_result, :correct)
      |> assign(:validation_msg, "")
      |> assign(:rule_descriptions, rule_descriptions)
      |> assign(:active_rules, active_rules)
      |> assign(:game_state, :waiting)
      |> assign(:game_time, 0)
      |> assign(:player_list, [])
      |> assign(:local_player, nil)

    {:ok, new_socket}
  end

  @impl true

  @impl true
  def handle_event("decline", _params, socket) do
    new_socket = validation("swipe-left", :invalid, socket)

    {:noreply, new_socket}
  end

  def handle_event("approve", _params, socket) do
    new_socket = validation("swipe-right", :valid, socket)

    {:noreply, new_socket}
  end

  @impl true
  def handle_event("join", %{"name" => name}, socket) do
    local_player = State.store_player(name, self())

    new_socket =
      socket
      |> assign(:local_player, local_player)

    {:noreply, new_socket}
  end

  @impl true
  def handle_event("ready", _params, socket) do
    local_player = socket.assigns.local_player
    {updated_local_player, _game_state} = State.player_ready(local_player.name)

    new_socket =
      socket
      |> assign(:local_player, updated_local_player)

    {:noreply, new_socket}
  end

  @impl true
  def handle_info({:game_start, game_state}, socket) do
    new_socket =
      socket
      |> assign(:game_state, game_state)

    {:noreply, new_socket}
  end

  @impl true
  def handle_info(:next_package, socket) do
    package = Logic.generate_package()

    new_socket =
      socket
      |> assign(:package, package)
      |> push_event("reset-package-card", %{})

    {:noreply, new_socket}
  end

  @impl true
  def handle_info({:game_end, game_state}, socket) do
    new_socket =
      socket
      |> assign(:game_state, game_state)

    {:noreply, new_socket}
  end

  @impl true
  def handle_info({:tick_update, current_game_time}, socket) do
    width = build_game_time_loading_bar(current_game_time)

    new_socket =
      socket
      |> push_event("timer-tick", %{time: current_game_time, width: width})

    {:noreply, new_socket}
  end

  def handle_info({:update_player_list, updated_player_list}, socket) do
    new_socket =
      socket
      |> assign(:player_list, updated_player_list)

    {:noreply, new_socket}
  end

  @impl true
  def handle_info(:update_rules, socket) do
    active_rules = State.get_stored_random_rules()
    rule_descriptions = Logic.descriptions_by_rules(active_rules)

    new_socket =
      socket
      |> assign(:rule_descriptions, rule_descriptions)
      |> assign(:active_rules, active_rules)

    {:noreply, new_socket}
  end

  @impl true
  def handle_info({:game_ended, game_state}, socket) do
    new_socket =
      socket
      |> assign(:game_state, game_state)

    {:noreply, new_socket}
  end

  def build_game_time_loading_bar(game_time) do
    max_game_time = State.max_game_time()
    game_time / max_game_time * 100
  end

  defp validation(swipe_direction, expected, socket) do
    package = socket.assigns.package

    {updated_player, decision, validation_msg} =
      State.update_player_score(self(), package, expected)

    new_socket =
      socket
      |> assign(:validation_result, decision)
      |> assign(:validation_msg, validation_msg)
      |> assign(:local_player, updated_player)
      |> assign(:score, updated_player.score)
      |> push_event(swipe_direction, %{})

    Process.send_after(self(), :next_package, @time_to_respond)

    new_socket
  end

  def get_medal(place) do
    Enum.at(["🥇", "🥈", "🥉"], place)
  end
end
