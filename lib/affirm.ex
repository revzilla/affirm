defmodule Affirm do
  @moduledoc """
  Affirm client library for Elixir.

  For api reference, please visit:
  https://docs.affirm.com/Integrate_Affirm/Direct_API

  Defines a `__using__` macro for ease of use inside implementation modules
  For example:
      defmodule AffirmService do
        use Affirm

        def attempt_capture(charge_id) do
          case capture(charge_id) do
            {:ok, response} -> # do success things
            {:error, message} -> # do failure things
          end
        end
      end
  """
  defmodule ConfigError do
    defexception [:message]

    @spec exception(String.t()) :: struct
    def exception(value) do
      message = "missing config for :#{value}"

      %ConfigError{message: message}
    end
  end

  defmacro __using__(_) do
    quote do
      import Affirm.API
    end
  end

  @doc """
  Convenience function for retrieving Affirm specfic environment values, but
  will raise an exception if values are missing.
  ## Example
      iex> Affirm.get_env(:random_value)
      ** (Affirm.ConfigError) missing config for :random_value
  """
  @spec get_env(atom) :: any
  def get_env(key) do
    Application.get_env(:affirm, key) || raise ConfigError, key
  end
end
