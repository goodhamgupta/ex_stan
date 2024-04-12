defmodule ExStan do
  @moduledoc """
  **ExStan** is a Elixir interface to Stan, a package for Bayesian inference.

  Stan® is a state-of-the-art platform for statistical modeling and
  high-performance statistical computation. Thousands of users rely on Stan for
  statistical modeling, data analysis, and prediction in the social, biological,
  and physical sciences, engineering, and business.

  This project is primarily based on the [PyStan](https://github.com/stan-dev/pystan) repository.
  """

  require Logger

  alias ExStan.Model
  alias ExStan.Client

  @doc """
  Builds (compiles) a Stan program.

  ## Parameters

  - `program_code`: Stan program code describing a Stan model.
  - `data`: An Elixir map providing the data for the model. Variable names are the keys and the values are their associated values. Default is an empty map, suitable for Stan programs with no `data` block.
  - `random_seed`: Random seed, a positive integer for random number generation. Used to ensure that results can be reproduced.

  ## Returns

  - `Model`: an instance of Model

  ## Notes

  C++ reserved words and Stan reserved words may not be used for variable names; see the Stan User's Guide for a complete list.
  """
  def build(program_code, data \\ %{}, random_seed \\ nil) do
    program_code
    |> do_build()
    |> handle_build_response()
    |> post_model_params(data)
    |> validate_model_params()
    |> create_model_struct(program_code, data, random_seed)
  end

  defp do_build(program_code) do
    Logger.info("Building model..")
    response = Client.post("/models", %{"program_code" => program_code})

    case response.status do
      201 ->
        Logger.info("Model created")
        response

      _ ->
        Logger.error("Model creation unsuccesful")
        IO.inspect(response)
    end
  end

  defp handle_build_response(response) do
    if response.status != 201 do
      raise RuntimeError, message: "Error: #{response.body}"
    else
      if Map.has_key?(response.body, "stanc_warnings") do
        Logger.info("Messages from stanc: #{response.body["stanc_warnings"]}")
      end
    end

    response
  end

  defp post_model_params(response, data) do
    response = Client.post("/#{response.body["name"]}/params", %{"data" => data})

    if response.status != 200 do
      raise "Error: #{Jason.encode!(response.body)}"
    end

    response
  end

  defp validate_model_params(response) do
    params_list = response.body["params"]

    val =
      Enum.count(Enum.map(params_list, fn param -> param["name"] end)) ==
        Enum.count(params_list)

    if val != true do
      raise ArgumentError,
        message: "Validation Error: Duplicate parameter names detected in the model."
    end

    response
  end

  defp create_model_struct(response, program_code, data, random_seed) do
    params_list = response.body["params"]

    result =
      Enum.map(params_list, fn param ->
        {param["constrained_names"], param["name"], param["dims"]}
      end)

    %Model{
      model_name: response.body["name"],
      program_code: program_code,
      data: data,
      param_names: Enum.map(result, fn {_, name, _} -> name end),
      constrained_param_names: Enum.map(result, fn {constrained, _, _} -> List.flatten(constrained) end),
      dims: Enum.map(result, fn {_, _, dims} -> dims end),
      random_seed: random_seed
    }
  end
end
