# ExStan

**ExStan** is a Elixir interface to Stan, a package for Bayesian inference.

Stan® is a state-of-the-art platform for statistical modeling and
high-performance statistical computation. Thousands of users rely on Stan for
statistical modeling, data analysis, and prediction in the social, biological,
and physical sciences, engineering, and business.

This project is primarily based on the [PyStan](https://github.com/stan-dev/pystan) repository.

## Installation

The package can be installed by adding `ex_stan` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_stan, "~> 0.1.0"}
  ]
end
```

ExStan requires the [httpstan](https://github.com/stan-dev/httpstan/) package to facilitate communication with the Stan compiler via the httpstan server. Installation methods vary by operating system: for most systems, `httpstan` can be installed using `pip`, while MacOS users must compile it from the source code.


## Credits

This package is based entirely on the PyStan and RStan SDKs.