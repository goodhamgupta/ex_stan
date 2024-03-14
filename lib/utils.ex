defmodule ExStan.Utils do
  def split_data(data) do
    Enum.reduce(data, [[], [], [], [], [], []], fn {k, v},
                                                   [
                                                     names_r,
                                                     values_r,
                                                     dim_r,
                                                     names_i,
                                                     values_i,
                                                     dim_i
                                                   ] ->
      tensor = Nx.tensor(v)

      case Nx.type(tensor) do
        {:f, _} ->
          [
            [k | names_r],
            [tensor |> Nx.to_flat_list() | values_r],
            [Tuple.to_list(Nx.shape(tensor)) | dim_r],
            names_i,
            values_i,
            dim_i
          ]

        {:s, _} ->
          [
            names_r,
            values_r,
            dim_r,
            [k | names_i],
            [tensor |> Nx.to_flat_list() | values_i],
            [Tuple.to_list(Nx.shape(tensor)) | dim_i]
          ]

        _ ->
          raise "Variable must be float or integer type"
      end
    end)
  end
end
