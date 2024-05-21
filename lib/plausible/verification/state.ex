defmodule Plausible.Verification.State do
  @moduledoc """
  The struct and interface describing the state of the site verification process.
  Assigns are meant to be used to communicate between checks, while diagnostics
  are later on interpreted (translated into user-friendly messages and recommendations)
  via `Plausible.Verification.Diagnostics` module.
  """
  defstruct url: nil,
            data_domain: nil,
            report_to: nil,
            assigns: %{},
            diagnostics: %Plausible.Verification.Diagnostics{}

  @type t() :: %__MODULE__{}

  def assign(%__MODULE__{} = state, assigns) do
    %{state | assigns: Map.merge(state.assigns, Enum.into(assigns, %{}))}
  end

  def put_diagnostics(%__MODULE__{} = state, diagnostics) when is_list(diagnostics) do
    %{state | diagnostics: struct!(state.diagnostics, diagnostics)}
  end

  def put_diagnostics(%__MODULE__{} = state, diagnostics) do
    put_diagnostics(state, List.wrap(diagnostics))
  end

  def notify_start(state, check, slowdown \\ 0) do
    if is_pid(state.report_to) do
      if is_integer(slowdown) and slowdown > 0, do: :timer.sleep(slowdown)
      send(state.report_to, {:verification_check_start, {check, state}})
    end

    state
  end

  def notify_verification_end(state, slowdown \\ 0) do
    if is_pid(state.report_to) do
      if is_integer(slowdown) and slowdown > 0, do: :timer.sleep(slowdown)
      send(state.report_to, {:verification_end, state})
    end

    state
  end
end
