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

  defp validate(%Fit{num_flat: num_flat, constrained_param_names: constrained_param_names})
       when num_flat != length(constrained_param_names) do
    raise ArgumentError,
          "num_flat and constrained_param_names must have the same length. Given: num_flat=#{num_flat}, constrained_param_names=#{constrained_param_names}"
  end

  defp validate(obj), do: obj

  defp parse_draws(%Fit{} = fit) do
    fit
    |> Map.put(:_draws, nil)
    |> Enum.with_index()
    |> Enum.reduce(fit, fn {stan_output, chain_index}, acc ->
      draw_index = 0

      stan_output
      |> String.split("\n")
      |> Enum.reduce(acc, fn line, acc ->
        msg = Jason.decode!(line)

        if Map.get(msg, "topic") == "sample" do
          values = Map.get(msg, "values")

          if not is_map(values) do
            acc
          else
            acc =
              if is_nil(acc._draws) do
                feature_names = Map.keys(values)

                sample_and_sampler_param_names =
                  Enum.filter(feature_names, fn name -> String.ends_with?(name, "__") end)

                num_rows =
                  length(sample_and_sampler_param_names) + length(acc.constrained_param_names)

                tmp_acc =
                  Map.put(
                    acc,
                    :_draws,
                    Nx.broadcast(0, {num_rows, acc.num_samples, acc.num_chains})
                  )

                if length(acc.constrained_param_names) > 0 and
                     String.ends_with?(List.last(feature_names), "__") do
                  raise "Expected last parameter name to be one declared in program code, found `#{List.last(feature_names)}`"
                end

                Map.put(tmp_acc, :sample_and_sampler_param_names, sample_and_sampler_param_names)
              end

            draw_row = Map.values(values)

            acc =
              Map.update!(acc, :_draws, fn draws ->
                Nx.put_slice(draws, {:*, draw_index, chain_index}, draw_row)
              end)

            Map.put(acc, :draw_index, draw_index + 1)
          end
        else
          acc
        end
      end)
    end)
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
