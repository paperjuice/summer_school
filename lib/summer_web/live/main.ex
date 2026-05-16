defmodule SummerWeb.MainLive do
  use SummerWeb, :live_view

  alias Summer.Logic
  @time_to_respond 1000

  @impl true
  def mount(_params, _session, socket) do
    package = Logic.generate_package()
    timestamp = DateTime.utc_now() |> DateTime.to_unix()
    new_socket =
      socket
      |> assign(:package, package)
      |> assign(:score, 0)
      |> assign(:timestamp, timestamp)
      |> assign(:validation_result, :correct) #:incorrect
      |> assign(:validation_msg, "")

    {:ok, new_socket}
  end

  @impl true
  def handle_event("approve", _params, socket) do
    package = socket.assigns.package
    score = socket.assigns.score

    {validation_result, validation_msg} =
      Logic.validate(package)

    decision =
      if validation_result == :valid,
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
      |> push_event("swipe-right", %{})

    Process.send_after(self(), :next_package, @time_to_respond)

    {:noreply, new_socket}
  end

  @impl true
  def handle_event("decline", _params, socket) do
    score = socket.assigns.score
    package = socket.assigns.package

    {validation_result, validation_msg} =
      Logic.validate(package)

    decision =
      if validation_result == :invalid,
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
      |> push_event("swipe-left", %{})

    Process.send_after(self(), :next_package, @time_to_respond)

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
end
