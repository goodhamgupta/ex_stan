defmodule Distributions.BasicNormalTest do
  use ExUnit.Case

  alias ExStan.Model

  test "build" do
    program_code = "parameters {real y;} model {y ~ normal(0,1);}"
    result = ExStan.build(program_code)
    assert !is_nil(result.model_name)
  end
end
