defmodule Affirm.TestHelpers do
  @doc "Creates a Bypass listener to act as a double for the actual Affirm API endpoints"
  @spec build_bypass :: any
  def build_bypass do
    bypass = Bypass.open()
    Application.put_env(:affirm, :url, "http://localhost:#{bypass.port}")
    bypass
  end

  @doc "Simulates that the provided Bypass listener is not accepting connections"
  @spec simulate_service_down(any) :: nil
  def simulate_service_down(bypass) do
    Bypass.down(bypass)
    nil
  end

  @spec simulate_service_response(any, Plug.Conn.status(), String.t(), (Plug.Conn.t() -> boolean)) :: no_return
  def simulate_service_response(bypass, status, body, fun) when is_function(fun) do
    Bypass.expect(bypass, fn conn ->
      if fun.(conn |> Plug.Conn.fetch_query_params()) do
        Plug.Conn.resp(conn, status, body)
      end
    end)
  end

  @spec successful_authorization_response_string(String.t()) :: String.t()
  def successful_authorization_response_string(amount, order_id \\ nil) do
    ~s(
        {"id":"ALO4-UVGR","created":"2016-03-18T19:19:04Z","currency":"USD","amount":#{amount},
        "auth_hold":6100,"payable":0,"void":false,"expires":"2016-04-18T19:19:04Z",
        "order_id":"#{order_id}","events":[{"created":"2014-03-20T14:00:33Z","currency":"USD",
        "id":"UI1ZOXSXQ44QUXQL","transaction_id":"TpR3Xrx8TkvuGio0","type":"auth"}],
        "details":{"items":{"sweater-a92123":{"sku":"sweater-a92123","display_name":"Sweater","qty":1,
        "item_type":"physical","item_image_url":"http://placehold.it/350x150","item_url":"http://placehold.it/350x150",
        "unit_price":5000}},"order_id":"#{order_id}","shipping_amount":400,"tax_amount":700,
        "shipping":{"name":{"full":"JohnDoe"},"address":{"line1":"325PacificAve","city":"SanFrancisco",
        "state":"CA","zipcode":"94112","country":"USA"}},"discounts":{"RETURN5":{"discount_amount":500,
        "discount_display_name":"Returningcustomer5%discount"},"PRESDAY10":{"discount_amount":1000,
        "discount_display_name":"President'sDay10%off"}}}}
    )
  end

  @spec successful_capture_response_string(String.t(), String.t()) :: String.t()
  def successful_capture_response_string(amount, fee) do
    ~s({"fee":#{fee},"created":"2016-03-18T00:03:44Z","order_id":"JKLM4321","currency":"USD",
    "amount":#{amount},"type":"capture","id":"O5DZHKL942503649","transaction_id":"6dH0LrrgUaMD7Llc"})
  end

  @spec successful_void_response_string() :: String.t()
  def successful_void_response_string() do
    ~s({"type":"void","id":"N5E9OXSIDJ8TKZZ9","transaction_id":"G9TqohxBlRPWTGB2",
    "created":"2014-03-17T22:52:16Z","order_id":"JLKM4321"})
  end

  @spec successful_refund_response_string(String.t(), String.t()) :: String.t()
  def successful_refund_response_string(amount, fee_refunded) do
    ~s({"created":"2014-03-18T19:20:30Z","fee_refunded":#{fee_refunded},"amount":#{amount},"type":"refund",
    "id":"OWA49MWUCA29SBVQ","transaction_id":"r86zdkHONPcaiVJJ"})
  end

  @spec failed_response_string(String.t()) :: String.t()
  def failed_response_string(code) do
    ~s({"status_code": 200, "code": "#{code}", "transaction_id": "12864241"})
  end

  @spec successful_read_response_string() :: String.t()
  def successful_read_response_string() do
    ~s({"id":"ALO4-UVGR","status":"auth","created":"2016-03-18T19:19:04Z","currency":"USD","amount":6100,
    "auth_hold":6100,"payable":0,"void":false,"expires":"2016-04-18T19:19:04Z","order_id":"JKLM4321",
    "events":[{"created":"2014-03-20T14:00:33Z","currency":"USD","id":"UI1ZOXSXQ44QUXQL",
    "transaction_id":"TpR3Xrx8TkvuGio0","type":"auth"}],"details":{"items":{"sweater-a92123":
    {"sku":"sweater-a92123","display_name":"Sweater","qty":1,"item_type":"physical",
    "item_image_url":"http://placehold.it/350x150","item_url":"http://placehold.it/350x150","unit_price":5000}},
    "order_id":"JKLM4321","shipping_amount":400,"tax_amount":700,"shipping":{"name":{"full":"John Doe"},"address":
    {"line1":"633 Folsom St","line2":"Floor 7","city":"San Francisco","state":"CA",
    "zipcode":"94112","country":"USA"}},"discounts":{"RETURN5":{"discount_amount":500,
    "discount_display_name":"Returning customer 5% discount"},
    "PRESDAY10":{"discount_amount":1000,"discount_display_name":"President's Day 10% off"}}}})
  end
end
