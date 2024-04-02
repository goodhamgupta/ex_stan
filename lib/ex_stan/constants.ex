defmodule ExStan.Constants do
  @moduledoc """
  Constants used in the ExStan library.
  This is a simplified version of the arguments module implemented in HTTPStan.
  The argument types are included in the priv directory under the filename "cmdstan-help-all.json"
  """

  @default_sample_num_flat 1
  @default_sample_num_samples 1000
  @default_sample_num_thin 1
  @defult_sample_num_warmup 1000
  @default_sample_save_warmup false

  @spec default_sample_num_flat() :: integer()
  def default_sample_num_flat(), do: @default_sample_num_flat
  @spec default_sample_num_samples() :: integer()
  def default_sample_num_samples(), do: @default_sample_num_samples
  @spec default_sample_num_thin() :: integer()
  def default_sample_num_thin(), do: @default_sample_num_thin
  @spec default_sample_num_warmup() :: integer()
  def default_sample_num_warmup(), do: @defult_sample_num_warmup
  @spec default_sample_save_warmup() :: boolean()
  def default_sample_save_warmup(), do: @default_sample_save_warmup
end
