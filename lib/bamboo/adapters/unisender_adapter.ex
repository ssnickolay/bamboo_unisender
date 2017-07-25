defmodule Bamboo.UnisenderAdapter do
  @service_name "Unisender"
  @behaviour Bamboo.Adapter
  @default_base_uri "https://api.unisender.com/ru"
  @send_message_path "api/sendEmail"

  import Bamboo.ApiError

  def deliver(email, config) do
    api_key = get_key(config)
    params = email |> convert_to_unisender_params(api_key) |> Poison.encode!
    uri = [base_uri(), "/", @send_message_path]

    case :hackney.post(uri, headers(), params, [:with_body]) do
      {:ok, status, _headers, response} when status > 299 ->
        filtered_params = params |> Poison.decode! |> Map.put("key", "[FILTERED]")
        raise_api_error(@service_name, response, filtered_params)
      {:ok, status, headers, response} ->
        %{status_code: status, headers: headers, body: response}
      {:error, reason} ->
        raise_api_error(inspect(reason))
    end
  end

  def handle_config(config) do
    config
  end

  def convert_to_unisender_params(params, api_key) do
    %{a: 1}
  end

  defp get_key(config) do
    case Map.get(config, :api_key) do
      nil -> raise_api_key_error(config)
      key -> key
    end
  end

  defp raise_api_key_error(config) do
    raise ArgumentError, """
    There was no API key set for the Unisender adapter.
    * Here are the config options that were passed in:
    #{inspect config}
    """
  end

  defp headers do
    [{"content-type", "application/json"}]
  end

  defp base_uri do
    Application.get_env(:bamboo, :unisender_base_uri) || @default_base_uri
  end
end