defmodule ExStan.Model do
  @base_url Application.compile_env(:ex_stan, :httpstan_url)

  @keys [
    :model_name,
    :program_code,
    :data,
    :param_names,
    :constrained_param_names,
    :dims,
    :random_seed
  ]

  defstruct @keys

  def build(program_code, data \\ %{}, _random_seed \\ nil) do
    start = :os.system_time(:second)
    response = do_build(program_code)
    handle_build_response(response, start)
    response = post_model_params(response, data)
    validate_model_params(response)
    create_model_struct(response)
  end

  defp do_build(program_code) do
    url = @base_url <> "/models"
    response = Req.post!(url, json: %{"program_code" => program_code})

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

  defp create_model_struct(response) do
    params_list = response.body["params"]
    require IEx
    IEx.pry()

    Enum.map(params_list, fn param ->
      {param["constrained_names"], param["name"], param["dims"]}
    end)
  end
end
