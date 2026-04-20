defmodule AppleBusinessRegistry.Error do
  @moduledoc "Structured error returned from the Apple Business Registry API."

  defexception [:message, :status, :details]

  @type t :: %__MODULE__{
          message: String.t(),
          status: non_neg_integer() | nil,
          details: term()
        }

  @doc "Create an error from an HTTP response."
  @spec from_http(non_neg_integer(), term()) :: t()
  def from_http(status, body) do
    %__MODULE__{
      message: reason_for(status),
      status: status,
      details: body
    }
  end

  defp reason_for(400), do: "bad request — invalid request format or parameters"
  defp reason_for(401), do: "unauthorized — token rejected by Apple Business Registry API"
  defp reason_for(403), do: "forbidden — Business Registry capability or key configuration issue"
  defp reason_for(404), do: "not found — business or location does not exist"
  defp reason_for(409), do: "conflict — resource already exists or has conflicting state"

  defp reason_for(422),
    do: "unprocessable entity — validation failed for business or location data"

  defp reason_for(429), do: "rate limited by Apple Business Registry API"
  defp reason_for(status) when status in 500..599, do: "Apple Business Registry API server error"
  defp reason_for(_), do: "Apple Business Registry API request failed"
end
