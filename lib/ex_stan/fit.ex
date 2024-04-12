defmodule ExStan.Fit do
  @moduledoc """
  Stores draws from one or more chains.

  Returned by methods of a `Model`. Users will not instantiate this class directly.

  A `Fit` instance provides a user-friendly view of draws, accessible via the `to_frame` method.
  """

  alias __MODULE__

  defstruct [
    :stan_outputs,
    :num_chains,
    :param_names,
    :feature_names,
    :constrained_param_names,
    :dims,
    :num_warmup,
    :num_samples,
    :num_thin,
    :num_flat,
    :save_warmup,
    :sample_and_sampler_param_names,
    :draws
  ]

  defp validate(%Fit{num_thin: num_thin}) when not is_integer(num_thin) do
    raise ArgumentError,
          "num_thin object cannot be interpreted as an integer. Given: num_thin=#{num_thin}"
  end

  defp validate(obj), do: obj

  defp parse_draws(%Fit{} = fit) do
    result = do_parse_draws(fit)

    Map.merge(fit, %{
      draws: result.draws,
      feature_names: result.feature_names,
      sample_and_sampler_param_names: result.sample_and_sampler_param_names
    })
  end

  defp do_parse_draws(fit) do
    Enum.with_index(fit.stan_outputs)
    |> Enum.reduce(nil, fn {stan_output, chain_index}, acc ->
      parse_stan_output(
        stan_output,
        chain_index,
        acc,
        fit
      )
    end)
  end

  defp parse_stan_output(
         stan_output,
         chain_index,
         acc,
         fit
       ) do
    String.split(stan_output, "\n")
    |> Enum.reduce(
      {acc, 0},
      &process_line(&1, &2, chain_index, fit)
    )
    |> elem(0)
  end

  defp process_line(
         line,
         {acc, draw_index},
         chain_index,
         fit
       ) do
    msg = decode_line(line)

    if Map.get(msg, "topic") == "sample" do
      process_sample(
        msg,
        acc,
        draw_index,
        chain_index,
        fit
      )
    else
      {acc, draw_index}
    end
  end

  defp decode_line(""), do: %{}
  defp decode_line(line), do: Jason.decode!(line)

  defp process_sample(
         msg,
         acc,
         draw_index,
         chain_index,
         fit
       ) do
    values = Map.get(msg, "values")

    if not is_map(values) do
      {acc, draw_index}
    else
      acc = initialize_acc_if_nil(acc, values, fit)
      update_draws(acc, values, draw_index, chain_index)
    end
  end

  defp initialize_acc_if_nil(nil, values, fit) do
    feature_names = Map.keys(values)
    sample_and_sampler_param_names = Enum.filter(feature_names, &String.ends_with?(&1, "__"))
    num_rows = length(sample_and_sampler_param_names) + length(fit.constrained_param_names)

    %{
      draws: Nx.broadcast(0, {num_rows, fit.num_samples, fit.num_chains}),
      feature_names: feature_names,
      sample_and_sampler_param_names: sample_and_sampler_param_names
    }
  end

  defp initialize_acc_if_nil(acc, _values, _fit),
    do: acc

  defp update_draws(acc, values, draw_index, chain_index) do
    draw_row = values |> Map.values() |> Nx.tensor()
    {shape} = Nx.shape(draw_row)
    indices = create_indices(shape, draw_index, chain_index)
    tmp = Nx.indexed_put(acc.draws, indices, draw_row)
    {%{acc | draws: tmp}, draw_index + 1}
  end

  defp create_indices(shape, draw_index, chain_index) do
    for i <- 0..(shape - 1) do
      [i, draw_index, chain_index]
    end
    |> Nx.tensor()
  end

  # Public API

  def new(opts) do
    %Fit{
      stan_outputs: Keyword.get(opts, :stan_outputs),
      num_chains: Keyword.get(opts, :num_chains),
      param_names: Keyword.get(opts, :param_names),
      constrained_param_names: Keyword.get(opts, :constrained_param_names),
      dims: Keyword.get(opts, :dims),
      num_warmup: Keyword.get(opts, :num_warmup),
      num_samples: Keyword.get(opts, :num_samples),
      num_thin: Keyword.get(opts, :num_thin),
      save_warmup: Keyword.get(opts, :save_warmup),
      num_flat: Keyword.get(opts, :num_flat, nil)
    }
    |> validate()
    |> parse_draws()
  end

  @doc """
  Converts the draws from a `Fit` struct into a data frame.

  ## Parameters

    - `%Fit{}`: A `Fit` struct containing the draws and feature names.

  ## Returns

  A `DataFrame` object with the draws as rows and feature names with chain and sample indexes as columns.

  ## Errors

  - Raises an error if the length of draws and columns do not match.
  - Raises an error if the `Explorer` module is not available.

  """
  def to_frame(%Fit{draws: draws, feature_names: feature_names}) do
    unless Code.ensure_loaded?(Explorer) do
      raise "Explorer is not available. Please install it using `mix deps.get`"
    end

    alias Explorer.DataFrame

    # TODO: O(N^3) complexity. Can be optimized.
    draws
    |> Nx.transpose()
    |> Nx.to_list()
    |> Enum.with_index(fn chain_elem, chain_idx ->
      Enum.with_index(chain_elem, fn sample_elem, sample_idx ->
        feature_names
        |> Enum.zip(sample_elem)
        |> Enum.into(%{})
        |> Map.merge(%{
          "sample_number" => sample_idx + 1,
          "chain_number" => chain_idx + 1
        })
      end)
    end)
    |> List.flatten()
    |> DataFrame.new()
  end
end
