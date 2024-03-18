defmodule ExStan do
  alias ExStan.Model
  @base_url Application.compile_env(:ex_stan, :httpstan_url)

  @doc """
  Builds (compiles) a Stan program.

  ## Parameters

  - `program_code`: Stan program code describing a Stan model.
  - `data`: An Elixir map providing the data for the model. Variable names are the keys and the values are their associated values. Default is an empty map, suitable for Stan programs with no `data` block.
  - `random_seed`: Random seed, a positive integer for random number generation. Used to ensure that results can be reproduced. Currently not implemented.

  ## Returns

  - `Model`: an instance of Model

  ## Notes

  C++ reserved words and Stan reserved words may not be used for variable names; see the Stan User's Guide for a complete list.
  """
  def build(program_code, data \\ %{}, _random_seed \\ nil) do
    start = :os.system_time(:second)
    response = do_build(program_code)
    handle_build_response(response, start)
    response = post_model_params(response, data)
    validate_model_params(response)
    create_model_struct(program_code, data, response)
  end

  defp do_build(program_code) do
    url = @base_url <> "/models"
    response = Req.post!(url, json: %{"program_code" => program_code}, receive_timeout: 60_000)

    case response.status do
      201 ->
        IO.puts("Model created")
        response

      _ ->
        IO.puts("Model creation unsuccesful")
        IO.inspect(response)
    end
  end

  defp handle_build_response(response, start) do
    if response.status != 201 do
      raise "Error: #{response.body}"
    else
      IO.puts("Building: #{:os.system_time(:second) - start}s, done.")

      if Map.has_key?(response.body, "stanc_warnings") do
        IO.puts("Messages from stanc: #{response.body["stanc_warnings"]}")
      end
    end
  end

  defp post_model_params(response, data) do
    url = @base_url <> "/#{response.body["name"]}/params"
    response = Req.post!(url, json: %{"data" => data})

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
      raise "Error: duplicate parameter names"
    end
  end

  defp create_model_struct(program_code, data, response) do
    params_list = response.body["params"]

    result =
      Enum.map(params_list, fn param ->
        {param["constrained_names"], param["name"], param["dims"]}
      end)

    constrained_names = for {first, _, _} <- result, do: first |> List.flatten()
    param_names = for {_, second, _} <- result, do: second
    param_dims = for {_, _, third} <- result, do: third

    %Model{
      model_name: response.body["name"],
      program_code: program_code,
      data: data,
      param_names: param_names,
      constrained_param_names: constrained_names,
      dims: param_dims,
      random_seed: response.body["random_seed"]
    }
  end
end
