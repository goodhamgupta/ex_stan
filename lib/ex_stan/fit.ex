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
    :constrained_param_names,
    :dims,
    :num_warmup,
    :num_samples,
    :num_thin,
    :num_flat,
    :save_warmup,
    :sample_and_sampler_param_names,
    :_draws
  ]

  defp validate(%Fit{num_thin: num_thin}) when not is_integer(num_thin) do
    raise ArgumentError,
          "num_thin object cannot be interpreted as an integer. Given: num_thin=#{num_thin}"
  end

  defp validate(obj), do: obj

  defp parse_draws(
         %Fit{
           stan_outputs: stan_outputs,
           num_samples: num_samples,
           num_chains: num_chains,
           constrained_param_names: constrained_param_names
         } = fit
       ) do
    result = do_parse_draws(stan_outputs, num_samples, num_chains, constrained_param_names)

    Map.merge(fit, %{
      _draws: result.draws,
      sample_and_sampler_param_names: result.sample_and_sampler_param_names
    })
  end

  defp do_parse_draws(stan_outputs, num_samples, num_chains, constrained_param_names) do
    Enum.with_index(stan_outputs)
    |> Enum.reduce(nil, fn {stan_output, chain_index}, acc ->
      parse_stan_output(
        stan_output,
        chain_index,
        acc,
        num_samples,
        num_chains,
        constrained_param_names
      )
    end)
  end

  defp parse_stan_output(
         stan_output,
         chain_index,
         acc,
         num_samples,
         num_chains,
         constrained_param_names
       ) do
    String.split(stan_output, "\n")
    |> Enum.reduce(
      {acc, 0},
      &process_line(&1, &2, chain_index, num_samples, num_chains, constrained_param_names)
    )
    |> elem(0)
  end

  defp process_line(
         line,
         {acc, draw_index},
         chain_index,
         num_samples,
         num_chains,
         constrained_param_names
       ) do
    msg = decode_line(line)

    if Map.get(msg, "topic") == "sample" do
      process_sample(
        msg,
        acc,
        draw_index,
        chain_index,
        num_samples,
        num_chains,
        constrained_param_names
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
         num_samples,
         num_chains,
         constrained_param_names
       ) do
    values = Map.get(msg, "values")

    if not is_map(values) do
      {acc, draw_index}
    else
      acc = initialize_acc_if_nil(acc, values, num_samples, num_chains, constrained_param_names)
      update_draws(acc, values, draw_index, chain_index)
    end
  end

  defp initialize_acc_if_nil(nil, values, num_samples, num_chains, constrained_param_names) do
    feature_names = Map.keys(values)
    sample_and_sampler_param_names = Enum.filter(feature_names, &String.ends_with?(&1, "__"))
    num_rows = length(sample_and_sampler_param_names) + length(constrained_param_names)

    %{
      draws: Nx.broadcast(0, {num_rows, num_samples, num_chains}),
      sample_and_sampler_param_names: sample_and_sampler_param_names
    }
  end

  defp initialize_acc_if_nil(acc, _values, _num_samples, _num_chains, _constrained_param_names),
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

  def contains?(%Fit{param_names: param_names}, key) do
    Enum.member?(param_names, key)
  end

  def to_frame(%Fit{
        _draws: draws,
        sample_and_sampler_param_names: sample_and_sampler_param_names,
        constrained_param_names: constrained_param_names
      }) do
    if Code.ensure_loaded?(Explorer) do
      # alias Explorer.DataFrame

      columns = sample_and_sampler_param_names ++ constrained_param_names

      if length(draws) == length(columns) do
        # draws
        # |> DataFrame.new(columns: columns).rename(:index, "draws").rename(:columns, "parameters")
        :ok
      else
        raise "Length of draws and columns do not match"
      end
    else
      raise "Explorer is not available. Please install it using `mix deps.get`"
    end
  end

  def len(%Fit{param_names: param_names}) do
    Enum.count(param_names)
  end
end
