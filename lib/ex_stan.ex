defmodule ExStan do
  @on_load :load_nif
  @moduledoc """
  Documentation for `ExStan`.
  """

  def load_nif do
    :erlang.load_nif('lib/src/native', 0)
  end

  def add(_x, _y) do
    raise "NIF add/2 not implemented"
  end

  def new_model(x, y, z) do
    :erlang.apply(:"Elixir.ExStan", :new_model, [x, y, z])
  end
end
