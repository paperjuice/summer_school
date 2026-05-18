defmodule SummerWeb.MainLive do
  use SummerWeb, :live_view

  alias Summer.Logic
  alias Summer.State

  @time_to_respond 1000

  @impl true
  def mount(_params, _session, socket) do
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

    {:ok, new_socket}
  end

  @impl true
  def handle_event("approve", _params, socket) do
    new_socket = validation("swipe-right", :valid, socket)

    {:noreply, new_socket}
  end

  @impl true
  def handle_event("decline", _params, socket) do
    new_socket = validation("swipe-left", :invalid, socket)

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

  def capitalise(term) do
    String.capitalize("#{term}")
  end

  defp validation(swipe_direction, expected, socket) do
    package = socket.assigns.package
    score = socket.assigns.score
    active_rules = socket.assigns.active_rules

    {validation_result, validation_msg} =
      Logic.validate(package, active_rules)

    decision =
      if validation_result == expected,
        do: :correct,
        else: :incorrect

    new_score =
      if decision == :correct,
        do: score + 1,
        else: score - 1

    new_socket =
      socket
      |> assign(:validation_result, decision)
      |> assign(:validation_msg, validation_msg)
      |> assign(:score, new_score)
      |> push_event(swipe_direction, %{})

    Process.send_after(self(), :next_package, @time_to_respond)

    new_socket
  end
end
