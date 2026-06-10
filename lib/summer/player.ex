defmodule Summer.Player do
  @type t :: %__MODULE__{
          name: String.t(),
          score: pos_integer(),
          pid: pid(),
          ready?: boolean()
        }

  defstruct name: "",
            score: 0,
            pid: nil,
            ready?: false
end
