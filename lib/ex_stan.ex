defmodule ExStan do

  alias ExStan.Utils

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
    raise "NIF new_model/3 not implemented"
  end

  def new_array_var_context(x) do
    raise "NIF new_array_var_context/1 not implemented"
  end

end
