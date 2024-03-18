defmodule ExStan.Model do

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

end
