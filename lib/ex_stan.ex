defmodule ExStan do

  @on_load :load_nif
  @moduledoc """
  Documentation for `ExTg`.
  """

  @doc """
  ## Examples

      iex> ExTg.load_nif()
      :world

  """
  def load_nif do
    :erlang.load_nif('lib/src/native', 0)
  end

  def add(x, y) do
    raise "NIF add/2 not implemented"
  end

end
