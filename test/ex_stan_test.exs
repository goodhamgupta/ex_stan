defmodule ExStanTest do
  use ExUnit.Case
  doctest ExStan

  test "greets the world" do
    assert ExStan.hello() == :world
  end
end
