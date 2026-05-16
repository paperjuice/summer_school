defmodule SummerWeb.MainLive do
  use SummerWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_event("approve", _params, socket) do
    socket =
      socket

    Process.send_after(self(), :next_package, 1000)

    {:noreply, socket}
  end

  def handle_event("decline", _params, socket) do
    socket =
      socket

    Process.send_after(self(), :next_package, 1000)

    {:noreply, socket}
  end

  def handle_info(:next_package, socket) do
    new_socket = push_event(socket, "reset-package-card", %{})
    {:noreply, new_socket}
  end
end
