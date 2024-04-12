defmodule ExStan.Client do
  @moduledoc """
  Lightweight client for interacting with the HTTPStan server.
  """

  require Logger

  @base_url Application.compile_env(:ex_stan, :httpstan_url, "http://localhost:8080/v1")

  @receive_timeout 60_000

  @doc """
  Sends a GET request to the specified path.
  """
  def get(path \\ "") do
    url = "#{@base_url}#{path}"
    Logger.debug("GET #{url}")
    Req.get!(url, receive_timeout: @receive_timeout)
  end

  @doc """
  Sends a POST request to the specified path with the given body.
  """
  def post(path \\ "", body) do
    url = "#{@base_url}#{path}"
    Logger.debug("POST #{url}")
    Req.post!(url, json: body, receive_timeout: @receive_timeout)
  end

  @doc """
  Sends a DELETE request to the specified path.
  """
  def delete(path \\ "") do
    url = "#{@base_url}#{path}"
    Logger.debug("DELETE #{url}")
    Req.delete!(url, receive_timeout: @receive_timeout)
  end
end
