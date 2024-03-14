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

                acc = Map.put(acc, :_draws, Nx.empty({num_rows, acc.num_samples, acc.num_chains}))

                if length(acc.constrained_param_names) > 0 and
                     String.ends_with?(List.last(feature_names), "__") do
                  raise "Expected last parameter name to be one declared in program code, found `#{List.last(feature_names)}`"
                end

                Map.put(acc, :sample_and_sampler_param_names, sample_and_sampler_param_names)
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

  def new(
        stan_outputs,
        num_chains,
        param_names,
        constrained_param_names,
        dims,
        num_warmup,
        num_samples,
        num_thin,
        num_flat \\ nil,
        save_warmup
      ) do
    %Fit{
      stan_outputs: stan_outputs,
      num_chains: num_chains,
      param_names: param_names,
      constrained_param_names: constrained_param_names,
      dims: dims,
      num_warmup: num_warmup,
      num_samples: num_samples,
      num_thin: num_thin,
      num_flat: num_flat,
      save_warmup: save_warmup
    }
    |> validate()
    |> parse_draws()
  end

  def contains?(%Fit{param_names: param_names}, key) do
    Enum.member?(param_names, key)
  end

  def to_frame(%Fit{
        _draws: _draws,
        sample_and_sampler_param_names: sample_and_sampler_param_names,
        constrained_param_names: constrained_param_names
      }) do
    if Code.ensure_loaded?(Explorer) do
      alias Explorer.DataFrame
      :ok
    else
      raise "Explorer is not available. Please install it using `mix deps.get`"
    end

    # This function requires pandas which is not available in Elixir.
    # You can convert the data to CSV or any other format and then use pandas in Python to convert it to a DataFrame.
  end

  def get_item(
        %Fit{
          param_names: param_names,
          dims: dims,
          _draws: _draws,
          num_samples: num_samples,
          num_thin: num_thin,
          num_warmup: num_warmup,
          num_chains: num_chains
        },
        param
      ) do
    # This function is a placeholder. The actual implementation depends on the structure of _draws and other variables.
  end

  def len(%Fit{param_names: param_names}) do
    Enum.count(param_names)
  end

  def to_string(%__MODULE__{param_names: param_names, dims: dims, _draws: _draws}) do
    # This function is a placeholder. The actual implementation depends on the structure of _draws and other variables.
  end

  defp parameter_indexes(
         %__MODULE__{
           sample_and_sampler_param_names: sample_and_sampler_param_names,
           constrained_param_names: constrained_param_names,
           dims: dims,
           param_names: param_names
         },
         param
       ) do
    # This function is a placeholder. The actual implementation depends on the structure of _draws and other variables.
  end
end
