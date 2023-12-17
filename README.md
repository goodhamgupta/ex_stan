# ExStan

**TODO: Add description**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ex_stan` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_stan, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/ex_stan>.


## Compile NIF

Compile the NIF using the following command:

```sh
g++ -std=c++14 -I/Users/shubham.gupta/.asdf/installs/erlang/24.0/erts-12.0/include/ -Ilib/src/include/ -bundle -bundle_loader /Users/shubham.gupta/.asdf/installs/erlang/24.0/erts-12.0/bin/beam.smp -o lib/src/native.so -DBOOST_DISABLE_ASSERTS -DBOOST_PHOENIX_NO_VARIADIC_EXPRESSION -DSTAN_THREADS -D_REENTRANT -D_GLIBCXX_USE_CXX11_ABI=0 -O3  -L./lib/src/lib -ltbb -Wl,-rpath,/Users/shubham.gupta/shubham/ex_stan/lib/src/lib lib/src/stan_services.cpp
```
