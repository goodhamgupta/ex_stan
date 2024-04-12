defmodule ExStan.Model do
  @moduledoc """
  Stores data associated with a Stan model and proxies calls to Stan services.

  Returned by `ExStan.build`. Users will not instantiate this class directly.
  """

  alias ExStan.{Client, Constants, Fit}
  alias __MODULE__

  require Logger

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

  @hmc_nuts_diag_e_adapt_function "stan::services::sample::hmc_nuts_diag_e_adapt"
  @fixed_param_function "stan::services::sample::fixed_param"

  @current_and_max_iterations_regex ~r/Iteration:\s+(\d+)\s+\/\s+(\d+)/
  @delete_success_codes [200, 202, 204]
  @default_num_chains 4

  # Public API

  @doc """
  Draws samples from the model. For easy reference, documentation is copied from Pystan.

  Parameters in `params` will be passed to the default sample function.
  The default sample function is currently `stan::services::sample::hmc_nuts_diag_e_adapt`.
  Parameter names are identical to those used in CmdStan. See the CmdStan documentation for
  parameter descriptions and default values.

  The function also accepts all options supported by CmdStand. Specifically, `num_chains` indicates the number of independent processes
  to use when drawing samples.

  ## Returns
  - Fit: instance of Fit allowing access to draws.

  ## Examples
  User-defined initial values for parameters must be provided
  for each chain. Typically they will be the same for each chain.
  The following example shows how user-defined initial parameters
  are provided:

  ```
  program_code = "parameters {real y;} model {y ~ normal(0,1);}"
  posterior = ExStan.build(program_code)
  fit = ExStan.Model.sample(posterior, num_chains: 2, init: [{"y": 3}, {"y": 3}])
  ```
  """
  def sample(%Model{} = model, opts \\ []) do
    opts =
      if !Keyword.get(opts, :num_chains) do
        Keyword.put(opts, :num_chains, @default_num_chains)
      else
        opts
      end

    hmc_nuts_diag_e_adapt(model, opts)
  end

  @doc """
  Draws samples from the model using `stan::services::sample::hmc_nuts_diag_e_adapt`.

  Parameters in `opts` will be passed to `stan::services::sample::hmc_nuts_diag_e_adapt`. Parameter names are
  identical to those used in CmdStan. See the CmdStan documentation for
  parameter descriptions and default values.

  There is one exception: `num_chains`. `num_chains` is an
  ExStan-specific keyword argument. It indicates the number of
  independent processes to use when drawing samples.

  ## Returns

  - `%ExStan.Fit{}`: An instance of `%ExStan.Fit{}` allowing access to draws.
  """
  def hmc_nuts_diag_e_adapt(%Model{} = model, opts) do
    create_fit(model, opts ++ [{:function, @hmc_nuts_diag_e_adapt_function}])
  end

  @doc """
  Draws samples from the model using `stan::services::sample::fixed_param`.

  Parameters in `opts` will be passed to `stan::services::sample::fixed_param`. Parameter names are
  identical to those used in CmdStan. See the CmdStan documentation for
  parameter descriptions and default values.

  `num_chains` is an ExStan-specific argument indicating the number of
  independent processes to use when drawing samples.

  Returns:
  - `%ExStan.Fit{}`: An instance of `%ExStan.Fit{}` allowing access to draws.
  """
  def fixed_param(%Model{} = model, opts \\ []) do
    create_fit(model, opts ++ [{:function, @fixed_param_function}])
  end

  @doc """
  Calculate the log probability of a set of unconstrained parameters.

  Arguments:
      model: The model containing the data.
      unconstrained_parameters: A sequence of unconstrained parameters.
      include_tparams: Apply jacobian adjust transform for transformed parameters.
      include_gqs: Apply jacobian adjust transform for generated quantities.

  Returns:
      The log probability of the unconstrained parameters.

  Notes:
      The unconstrained parameters are passed to the log_prob
      function in stan::model.
  """
  def constrain_pars(
        %Model{data: data, model_name: model_name} = _model,
        unconstrained_parameters,
        include_tparams \\ true,
        include_gqs \\ true
      ) do
    payload = %{
      "data" => data,
      "unconstrained_parameters" => unconstrained_parameters,
      "include_tparams" => include_tparams,
      "include_gqs" => include_gqs
    }

    response = Client.post("/#{model_name}/write_array", payload)

    if response.status != 200 do
      raise RuntimeError, response.body
    else
      response.body["params_r_constrained"]
    end
  end

  @doc """
  Reads constrained parameter values from their specified context and returns a
  sequence of unconstrained parameter values.

  Arguments:
      model: The model containing the data.
      constrained_parameters: Constrained parameter values and their specified context

  Returns:
      A sequence of unconstrained parameters.

  Notes:
      The unconstrained parameters are passed to the `transform_inits` method of the
      `model_base` instance. See `model_base.hpp` in the Stan C++ library for details.
  """
  def unconstrain_pars(%Model{data: data, model_name: model_name}, constrained_parameters) do
    payload = %{
      "data" => data,
      "constrained_parameters" => constrained_parameters
    }

    response = Client.post("/#{model_name}/transform_inits", payload)

    if response.status != 200 do
      raise RuntimeError, response.body
    else
      response.body["params_r_unconstrained"]
    end
  end

  @doc """
  Calculate the log probability of a set of unconstrained parameters.

  Arguments:
      model: The model containing the data.
      unconstrained_parameters: A sequence of unconstrained parameters.
      adjust_transform: Apply jacobian adjust transform.

  Returns:
      The log probability of the unconstrained parameters.

  Notes:
      The unconstrained parameters are passed to the log_prob
      function in stan::model.
  """
  def log_prob(
        %Model{data: data, model_name: model_name},
        unconstrained_parameters,
        adjust_transform \\ true
      ) do
    payload = %{
      "data" => data,
      "unconstrained_parameters" => unconstrained_parameters,
      "adjust_transform" => adjust_transform
    }

    response = Client.post("/#{model_name}/log_prob", payload)

    if response.status != 200 do
      raise RuntimeError, response.body
    else
      response.body["log_prob"]
    end
  end

  @doc """
  Calculate the gradient of the log posterior evaluated at the unconstrained parameters.

  Arguments:
      model: The model containing the data.
      unconstrained_parameters: A sequence of unconstrained parameters.

  Returns:
      The gradient of the log posterior evaluated at the unconstrained parameters.

  Notes:
      The unconstrained parameters are passed to the log_prob_grad
      function in stan::model.
  """
  def grad_log_prob(%Model{data: data, model_name: model_name}, unconstrained_parameters) do
    payload = %{
      "data" => data,
      "unconstrained_parameters" => unconstrained_parameters
    }

    response = Client.post("/#{model_name}/log_prob_grad", payload)

    if response.status != 200 do
      raise RuntimeError, response.body
    else
      response.body["log_prob_grad"]
    end
  end

  defp validate(opts) do
    Enum.each([:chain, :data, :random_seed], fn key ->
      case {key, Keyword.has_key?(opts, key)} do
        {:chain, false} -> Logger.info("`chain` id is set automatically.")
        {:data, true} -> Logger.info("`data` is set in `build`.")
        {:random_seed, true} -> Logger.info("`random_seed` is set in `build`.")
        _ -> nil
      end
    end)
  end

  defp submit_chains(model_name, payloads) do
    Enum.map(payloads, fn payload ->
      response = Client.post("/#{model_name}/fits", payload)

      case response.status do
        422 ->
          raise ArgumentError, Jason.decode!(response.body)

        201 ->
          response.body

        _ ->
          raise RuntimeError, response.body["message"]
      end
    end)
  end

  defp do_check_chain_status(operation) do
    if operation["done"] do
      operation
    else
      resp = Client.get("/#{operation["name"]}")

      if resp.status == 404 do
        raise RuntimeError, resp.body["message"]
      end

      updated_operation = Map.merge(operation, resp.body)
      progress_message = operation["metadata"]["progress"]

      if progress_message do
        [iteration, iteration_max] =
          Regex.run(@current_and_max_iterations_regex, progress_message)
          |> Enum.drop(1)
          |> Enum.map(&String.to_integer/1)

        Logger.info(
          "Sampling: #{round(100 * iteration / iteration_max)}%",
          colors: [:green]
        )
      end

      updated_operation
    end
  end

  defp check_chain_status(operations) do
    case Enum.all?(operations, & &1["done"]) do
      true ->
        operations

      false ->
        operations
        |> Enum.map(&do_check_chain_status/1)
        |> check_chain_status()
    end
  end

  defp collect_stan_outputs(operations, random_seed) do
    Logger.info("Sampling: 100%, done.")

    Enum.map(operations, fn operation ->
      fit_name = operation["result"]["name"]

      if fit_name == nil do
        if !String.starts_with?(to_string(operation["result"]["code"]), "2") do
          raise RuntimeError, operation["result"]["message"]
        end

        message = operation["result"]["message"]

        if message =~ "ValueError('Initialization failed.')" do
          Logger.error("Sampling: Initialization failed.")
          raise RuntimeError, "Initialization failed."
        else
          raise RuntimeError, message
        end
      end

      resp = Client.get("/#{fit_name}")

      if resp.status != 200 do
        raise RuntimeError, resp.body["message"]
      end

      stan_output = resp.body

      # Clean up after ourselves when fit is uncacheable (no random seed)
      if random_seed == nil do
        resp = Client.delete("/#{fit_name}")

        if resp.status not in @delete_success_codes do
          raise RuntimeError, resp.body["message"]
        end
      end

      stan_output
    end)
  end

  defp handle_nonstandard_logger_messages(stan_outputs) do
    ns_logger_messages =
      Enum.flat_map(stan_outputs, fn stan_output ->
        String.split(stan_output, "\n")
        |> Enum.filter(&String.contains?(&1, "\"logger\""))
        |> Enum.map(&Jason.decode!/1)
        |> Enum.filter(fn msg ->
          msg["topic"] == "logger" and
            msg["values"] != ["info:"] and
            not Enum.any?(
              msg["values"],
              &(String.starts_with?(&1, "info:Iteration:") or
                  String.starts_with?(&1, "info: Elapsed Time:") or
                  String.starts_with?(&1, "info:" <> String.duplicate(" ", 15)))
            )
        end)
      end)

    if ns_logger_messages != [] do
      Logger.info("Messages received during sampling:")

      Enum.each(ns_logger_messages, fn msg ->
        text =
          msg["values"]
          |> List.first()
          |> String.replace("info:", "  ")
          |> String.replace("error:", "  ")

        if String.trim(text) != "" do
          Logger.info(text)
        end
      end)
    end
  end

  defp create_fit(%Model{} = model, opts_list) do
    validate(opts_list)

    num_chains = opts_list[:num_chains]

    # Remove `num_chains` from opts and store it
    # Need to convert keyword list to map to make it JSON-encodable
    opts = opts_list |> Keyword.delete(:num_chains) |> Enum.into(%{})

    # Copy opts and verify everything is JSON-encodable
    opts = Jason.decode!(Jason.encode!(opts))
    function = Map.get(opts, "function")

    # Special handling for `init`
    init = Map.get(opts, "init", Enum.map(1..num_chains, fn _ -> %{} end))

    if length(init) != num_chains do
      raise ArgumentError, "Initial values must be provided for each chain."
    end

    num_warmup = opts["num_warmup"] || Constants.default_sample_num_warmup()
    num_samples = opts["num_samples"] || Constants.default_sample_num_samples()
    num_thin = opts["num_thin"] || Constants.default_sample_num_thin()
    num_flat = opts["num_flat"] || Constants.default_sample_num_flat()
    save_warmup = opts["save_warmup"] || Constants.default_sample_save_warmup()

    payloads =
      Enum.map(1..num_chains, fn chain ->
        payload =
          Map.merge(opts, %{
            "function" => function,
            "chain" => chain,
            "data" => model.data,
            "init" => List.first(init)
          })

        if model.random_seed != nil do
          Map.put(payload, "random_seed", model.random_seed)
        else
          payload
        end
      end)

    try do
      stan_outputs =
        model.model_name
        |> submit_chains(payloads)
        |> check_chain_status()
        |> collect_stan_outputs(model.random_seed)

      handle_nonstandard_logger_messages(stan_outputs)

      fit =
        Fit.new(
          stan_outputs: stan_outputs,
          num_chains: num_chains,
          param_names: model.param_names,
          constrained_param_names: model.constrained_param_names |> List.flatten(),
          dims: model.dims,
          num_warmup: num_warmup,
          num_samples: num_samples,
          num_thin: num_thin,
          num_flat: num_flat,
          save_warmup: save_warmup
        )

      # TODO: Add support for custom plugins
      fit
    rescue
      e in RuntimeError ->
        Logger.error(e)
    end
  end
end
