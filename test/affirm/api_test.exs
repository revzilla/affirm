defmodule Affirm.APITest do
  use ExUnit.Case
  import Affirm.TestHelpers

  alias Affirm.API

  setup context do
    {:ok,
     url: Application.put_env(:affirm, :url, "https://sandbox.affirm.com/api/v2/charges"),
     customer_id: Application.put_env(:affirm, :public_key, "bogus"),
     code: Application.put_env(:affirm, :private_key, "bogus"),
     affirm_bypass: if(context[:skip_bypass], do: nil, else: build_bypass)}
  end

  test """
  raises ConfigError when appropriate config vars are not set
  """ do
    Application.put_env(:affirm, :url, nil)

    assert_raise Affirm.ConfigError, "missing config for :url", fn ->
      API.authorize(%{})
    end
  end

  test """
       when the service endpoint is down
       returns an error
       """,
       %{affirm_bypass: affirm_bypass} do
    affirm_bypass
    |> simulate_service_down

    {:error, error} = API.authorize(%{})

    assert error == ":econnrefused"
  end

  test """
       authorize/1
       successfully POSTS and receives a response
       """,
       %{affirm_bypass: affirm_bypass} do
    response = successful_authorization_response_string("4500")

    params = %{
      checkout_token: "bogus",
      order_id: 1
    }

    affirm_bypass
    |> simulate_service_response(:ok, response, fn conn -> conn.method == "POST" end)

    {:ok, response} = API.authorize(params)

    assert response.amount == 4500
    assert response.type == "auth"
    refute is_nil(response.charge_id)
    refute is_nil(response.transaction_id)
  end

  test """
       authorize/1
       successfully POSTS and receives an error response
       when authorization is declined
       """,
       %{affirm_bypass: affirm_bypass} do
    response = failed_response_string("auth-declined")

    params = %{
      checkout_token: "bogus",
      order_id: 1
    }

    affirm_bypass
    |> simulate_service_response(:ok, response, fn conn -> conn.method == "POST" end)

    {:error, %{message: message}} = API.authorize(params)
    assert message == "Charge authorization hold declined."
  end

  test """
       capture/2
       successfully POSTS and receives a success response
       when given valid capture_id
       """,
       %{affirm_bypass: affirm_bypass} do
    response = successful_capture_response_string("4500", "450")

    # These params are optional
    params = %{
      order_id: "bogus",
      shipping_carrier: "USPS",
      shipping_confirmation: "1Z23223"
    }

    affirm_bypass
    |> simulate_service_response(:ok, response, fn conn -> conn.method == "POST" end)

    {:ok, response} = API.capture("CAPTURE_ID", params)
    assert response.amount == 4500
    assert response.fee == 450
    assert response.type == "capture"
    refute is_nil(response.id)
    refute is_nil(response.transaction_id)
    refute is_nil(response.created)
    refute is_nil(response.order_id)
  end

  test """
       capture/2
       successfully POSTS and receives a failure response
       when capture amount is greater than the auth
       """,
       %{affirm_bypass: affirm_bypass} do
    response = failed_response_string("capture-greater-instrument")
    simulate_service_response(affirm_bypass, :ok, response, fn conn -> conn.method == "POST" end)

    {:error, %{message: message}} = API.capture("BOGUS", %{})
    assert message == "Charges on this instrument cannot be captured for more than the authorization hold amount."
  end

  test """
       capture/2
       successfully POSTS and receives a failure response
       when capture amount does not equal than the auth
       """,
       %{affirm_bypass: affirm_bypass} do
    response = failed_response_string("capture-unequal-instrument")
    simulate_service_response(affirm_bypass, :ok, response, fn conn -> conn.method == "POST" end)

    {:error, %{message: message}} = API.capture("BOGUS", %{})
    assert message =~ "Charges on this instrument cannot be captured for an amount unequal to authorization"
  end

  test """
       capture/2
       successfully POSTS and receives a failure response
       when capture is already voided
       """,
       %{affirm_bypass: affirm_bypass} do
    response = failed_response_string("capture-voided")
    simulate_service_response(affirm_bypass, :ok, response, fn conn -> conn.method == "POST" end)

    {:error, %{message: message}} = API.capture("BOGUS", %{})
    assert message =~ "Cannot capture voided charge."
  end

  test """
       capture/2
       successfully POSTS and receives a failure response
       when capture is declined
       """,
       %{affirm_bypass: affirm_bypass} do
    response = failed_response_string("capture-declined")
    simulate_service_response(affirm_bypass, :ok, response, fn conn -> conn.method == "POST" end)

    {:error, %{message: message}} = API.capture("BOGUS", %{})
    assert message =~ "Charge capture declined."
  end

  test """
       capture/2
       successfully POSTS and receives a failure response
       when the capture limit is exceeded
       """,
       %{affirm_bypass: affirm_bypass} do
    response = failed_response_string("capture-limit-exceeded")
    simulate_service_response(affirm_bypass, :ok, response, fn conn -> conn.method == "POST" end)

    {:error, %{message: message}} = API.capture("BOGUS", %{})
    assert message =~ "Max capture amount on charge exceeded."
  end

  test """
       capture/2
       successfully POSTS and receives a failure response
       when the authorization is expired
       """,
       %{affirm_bypass: affirm_bypass} do
    response = failed_response_string("expired-authorization")
    simulate_service_response(affirm_bypass, :ok, response, fn conn -> conn.method == "POST" end)

    {:error, %{message: message}} = API.capture("BOGUS", %{})
    assert message == "Cannot capture expired charge authorization hold."
  end

  test """
       void/1
       successfully POSTS and receives a success response
       when given valid capture_id
       """,
       %{affirm_bypass: affirm_bypass} do
    response = successful_void_response_string()

    affirm_bypass
    |> simulate_service_response(:ok, response, fn conn -> conn.method == "POST" end)

    {:ok, response} = API.void("CAPTURE_ID")
    assert response.type == "void"
    refute is_nil(response.id)
    refute is_nil(response.transaction_id)
    refute is_nil(response.created)
    refute is_nil(response.order_id)
  end

  test """
       refund/2
       successfully POSTS and receives a success response
       when given valid capture_id and params
       """,
       %{affirm_bypass: affirm_bypass} do
    response = successful_refund_response_string("5000", "500")
    params = %{amount: "5000"}

    affirm_bypass
    |> simulate_service_response(:ok, response, fn conn -> conn.method == "POST" end)

    {:ok, response} = API.refund("CAPTURE_ID", params)
    assert response.type == "refund"
    assert response.amount == 5000
    assert response.fee_refunded == 500
    refute is_nil(response.id)
    refute is_nil(response.transaction_id)
    refute is_nil(response.created)
  end

  test """
       refund/2
       successfully POSTS and receives a failure response
       when the refund limit is exceeded
       """,
       %{affirm_bypass: affirm_bypass} do
    response = failed_response_string("refund-exceeded")
    simulate_service_response(affirm_bypass, :ok, response, fn conn -> conn.method == "POST" end)

    {:error, %{message: message}} = API.refund("BOGUS", %{})
    assert message == "Max refund amount exceeded."
  end

  test """
       refund/2
       successfully POSTS and receives a failure response
       when the auth has not been captured yet
       """,
       %{affirm_bypass: affirm_bypass} do
    response = failed_response_string("refund-uncaptured")
    simulate_service_response(affirm_bypass, :ok, response, fn conn -> conn.method == "POST" end)

    {:error, %{message: message}} = API.refund("BOGUS", %{})
    assert message == "Cannot refund a charge that has not been captured."
  end

  test """
       refund/2
       successfully POSTS and receives a failure response
       when the capture_id has been voided
       """,
       %{affirm_bypass: affirm_bypass} do
    response = failed_response_string("refund-voided")
    simulate_service_response(affirm_bypass, :ok, response, fn conn -> conn.method == "POST" end)

    {:error, %{message: message}} = API.refund("BOGUS", %{})
    assert message == "Cannot refund voided charge."
  end

  test """
       refund/2
       successfully POSTS and receives a failure response
       when the capture is more than 120 days old
       """,
       %{affirm_bypass: affirm_bypass} do
    response = failed_response_string("refund-expired")
    simulate_service_response(affirm_bypass, :ok, response, fn conn -> conn.method == "POST" end)

    {:error, %{message: message}} = API.refund("BOGUS", %{})
    assert message == "Charges on this instrument must be refunded within 120 days of capture."
  end

  test """
       read/2
       successfully GETs and receives a success response containing status
       when given valid capture_id
       """,
       %{affirm_bypass: affirm_bypass} do
    response = successful_read_response_string()

    affirm_bypass
    |> simulate_service_response(:ok, response, fn conn -> conn.method == "GET" end)

    {:ok, response} = API.read("CAPTURE_ID")
    assert response.status == "auth"
    refute Enum.empty?(response.events)
  end
end
