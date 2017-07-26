defmodule Bamboo.UnisenderAdapter do
  @service_name "Unisender"
  @behaviour Bamboo.Adapter
  @default_base_uri "https://api.unisender.com/ru"
  @send_message_path "api/sendEmail"

  import Bamboo.ApiError

  def deliver(email, config) do
    api_key = get_key(config)
    params = query_params(api_key, email)
    uri = [base_uri(), "/", api_path(params)]

    case :hackney.post(uri, headers(), "", [:with_body]) do
      {:ok, status, _headers, response} when status > 299 ->
        error_response(status, response, params)
      {:ok, status, headers, response} ->
        %{status_code: status, headers: headers, body: response}
        |> handle_response(Poison.decode!(response), params)
      {:error, reason} ->
        raise_api_error(inspect(reason))
    end
  end

  def handle_config(config) do
    if config[:api_key] in [nil, ""] do
      raise_api_key_error(config)
    else
      config
    end
  end

  @doc false
  def supports_attachments?, do: false

  defp handle_response(%{status_code: status, body: response}, %{"error" => _}, params) do
    error_response(status, response, params)
  end
  defp handle_response(ok, _, _), do: ok

  defp error_response(status, response, params) do
    filtered_params = params |> Map.put("key", "[FILTERED]")
    raise_api_error(@service_name, response, filtered_params)
  end

  defp api_path(params) do
    to_string =
      params
      |> Enum.map(fn({k, v}) -> Enum.join([k, v], "=") end)
      |> Enum.join("&")
    Enum.join([@send_message_path, "?", to_string])
  end

  defp query_params(api_key, email) do
    #attachments_uri = Enum.join([new_uri, build_attachments(email.attachments)], "&")
    email
    |> convert_to_unisender_params
    |> Map.merge(%{api_key: api_key, format: :json})
  end

  defp convert_to_unisender_params(email) do
    [{_, email_to}] = email.to
    %{
      email: email_to,
      sender_name: email.from |> elem(0),
      sender_email: email.from |> elem(1),
      subject: email.subject,
      list_id: email.assigns[:list_id],
      body: email.html_body
    }
  end

  def build_attachments(arr) do
    [a] = arr
    "attachments[#{a.filename}]=#{String.from_char_list(a.data)}"
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
