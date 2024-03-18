defmodule ExStan.Model do
  alias ExStan.Fit
  alias __MODULE__

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

  @doc """
  Draws samples from the model. For easy reference, documentation is copied from Pystan.

  Parameters in `params` will be passed to the default sample function.
  The default sample function is currently `stan::services::sample::hmc_nuts_diag_e_adapt`.
  Parameter names are identical to those used in CmdStan. See the CmdStan documentation for
  parameter descriptions and default values.

  There is one exception: `num_chains`. `num_chains` is an
  ExStan-specific keyword argument. It indicates the number of
  independent processes to use when drawing samples.

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
  def sample(%Model{} = model, num_chains \\ 4, opts \\ %{}) do
    hmc_nuts_diag_e_adapt(model, num_chains, opts)
  end

  def hmc_nuts_diag_e_adapt(%Model{} = model, num_chains, opts) do
    create_fit(model, num_chains, opts, @hmc_nuts_diag_e_adapt_function)
  end

  defp create_fit(%Model{} = _model, _num_chains, _opts, _function) do
  end
end
