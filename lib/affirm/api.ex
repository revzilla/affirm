defmodule Affirm.API do
  @moduledoc """
  Affirm provides several API endpoints... this module defines functions to
  interact with the transactional endpoints authorize, capture, void and refund.

  For api reference, please visit:
  https://docs.affirm.com/Integrate_Affirm/Direct_API
  """

  import Affirm.HTTP
  alias Affirm.Response

  @doc """
  Affirm's Authorize endpoint requires post data containing a `checkout_token`
  and takes an optional `order_id`. If the token is valid, the request will return
  a `charge_id` that should be saved for future transactions.
  """
  @spec authorize(map) :: {:ok, Response.t()} | {:error, String.t()}
  def authorize(params) do
    :post
    |> request("", params, headers, options)
    |> parse_response
  end

  @doc """
  Capture takes a `charge_id` and optional map of post data. Will return a `Affirm.Response`
  struct containing details of the successful capture transaction.
  """
  @spec capture(String.t(), map) :: {:ok, Response.t()} | {:error, String.t()}
  def capture(charge_id, params) do
    :post
    |> request("/#{charge_id}/capture", params, headers, options)
    |> parse_response
  end

  @doc """
  Capture takes a `charge_id`. Will return a `Affirm.Response`
  struct containing details of the successful void transaction.
  """
  @spec void(String.t()) :: {:ok, Response.t()} | {:error, String.t()}
  def void(charge_id) do
    :post
    |> request("/#{charge_id}/void", %{}, headers, options)
    |> parse_response
  end

  @doc """
  Refund takes a `charge_id` and a map containing a refund `amount`.
  Will return a `Affirm.Response` struct containing details of the successful return transaction.
  """
  @spec refund(String.t(), map) :: {:ok, Response.t()} | {:error, String.t()}
  def refund(charge_id, params) do
    :post
    |> request("/#{charge_id}/refund", params, headers, options)
    |> parse_response
  end

  @doc """
  Refund takes an optional `charge_id`.
  Will return an `Affirm.Response` struct containing current charge status.
  Used to prevent duplicate charge attempts.
  """
  @spec read(String.t()) :: {:ok, Response.t()} | {:error, String.t()}
  def read(charge_id) do
    :get
    |> request("/#{charge_id}", %{}, headers, options)
    |> parse_response(false)
  end

  @spec parse_response(tuple, boolean) :: {:ok, Response.t()} | {:error, String.t()}
  defp parse_response(response, is_transactional \\ true)

  defp parse_response({:ok, body}, is_transactional) do
    {:ok, Response.new(body, is_transactional)}
  end

  defp parse_response({:error, reason}, _), do: {:error, reason}

  @spec headers() :: list(tuple)
  defp headers do
    [
      {"Content-Type", "application/json"},
      {"Authorization", basic_auth(Affirm.get_env(:public_key), Affirm.get_env(:private_key))}
    ]
  end

  @spec options() :: keyword()
  defp options do
    [
      {:timeout, 15_000},
      {:recv_timeout, 15_000}
    ]
  end

  @spec basic_auth(binary, binary) :: binary
  defp basic_auth(user, pass) do
    "Basic " <> :base64.encode("#{user}:#{pass}")
  end
end
