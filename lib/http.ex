defmodule Affirm.HTTP do
  @moduledoc """
  Base client for all server interaction, used by all endpoint specific
  modules. This request wrapper coordinates the remote server, headers,
  authorization and SSL options.

  This uses `HTTPoison.Base`, so all of the typical HTTP verbs are availble.

  Sample Affirm config:
    config :affirm,
      url: "base_api_url",
      public_key: "affirm_supplied_public_key",
      private_key: "affirm_supplied_private_key"
  """
  use HTTPoison.Base

  @spec request(atom, binary, binary, headers, Keyword.t()) ::
          {:ok, term()}
          | {:error, Affirm.Response.t()}
          | {:error, String.t()}
          | {:error, atom()}
          | {:error, term()}
  def request(method, url, body, headers \\ [], options \\ []) do
    method
    |> super(full_url(url), body, headers, options)
    |> process_response
  end

  @spec full_url(binary) :: binary
  def full_url(url) do
    Affirm.get_env(:url) <> url
  end

  ## HTTPoison Callbacks

  @doc false
  def process_request_body(body) when body == "" or body == %{}, do: ""

  def process_request_body(body) do
    Jason.encode!(body)
  end

  @doc false
  def process_response_body(body) do
    case Jason.decode(body) do
      {:ok, parsed_body} ->
        Enum.reduce(parsed_body, %{}, fn {key, val}, acc -> Map.put(acc, String.to_atom(key), val) end)

      {:error, _} ->
        body
    end
  end

  defp process_response({:ok, %HTTPoison.Response{status_code: 200, body: %{code: error_code} = body}}) do
    case fetch_error_code(error_code) do
      nil -> {:error, Affirm.Response.new(%{message: body["message"]})}
      message -> {:error, Affirm.Response.new(%{message: message})}
    end
  end

  defp process_response({:ok, %HTTPoison.Response{status_code: code, body: body}})
       when code >= 200 and code <= 399,
       do: {:ok, body}

  defp process_response({:ok, %HTTPoison.Response{status_code: 400}}), do: {:error, :invalid_request}
  defp process_response({:ok, %HTTPoison.Response{status_code: 401}}), do: {:error, :unauthorized}
  defp process_response({:ok, %HTTPoison.Response{status_code: 404}}), do: {:error, :not_found}
  defp process_response({:ok, %HTTPoison.Response{body: body}}), do: {:error, body}
  defp process_response({:error, ":econnrefused"}), do: {:error, :econnrefused}
  defp process_response({:error, %HTTPoison.Error{reason: reason}}), do: {:error, inspect(reason)}

  @doc """
  Provides a mapping from returned error code to error String.
  Affirm also provides this message in the returned response, but this
  provides an easier way of mocking/testing.
  """
  @spec fetch_error_code(String.t()) :: String.t() | nil
  def fetch_error_code(error_code) do
    # credo:disable-for-lines:2 Credo.Check.Readability.MaxLineLength
    code_map = %{
      "auth-declined" => "Charge authorization hold declined.",
      "capture-greater-instrument" =>
        "Charges on this instrument cannot be captured for more than the authorization hold amount.",
      "capture-unequal-instrument" =>
        "Charges on this instrument cannot be captured for an amount unequal to authorization hold amount.",
      "capture-voided" => "Cannot capture voided charge.",
      "partial-capture-instrument" => "Charges on this instrument cannot be partially captured.",
      "refund-exceeded" => "Max refund amount exceeded.",
      "refund-uncaptured" => "Cannot refund a charge that has not been captured.",
      "refund-voided" => "Cannot refund voided charge.",
      "capture-declined" => "Charge capture declined.",
      "capture-limit-exceeded" => "Max capture amount on charge exceeded.",
      "expired-authorization" => "Cannot capture expired charge authorization hold.",
      "refund-expired" => "Charges on this instrument must be refunded within 120 days of capture.",
      "financial-product-invalid" => "Please provide a valid financial product key.",
      "invalid_field" => "An input field resulted in invalid request."
    }

    code_map[error_code]
  end
end
