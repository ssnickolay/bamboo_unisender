defmodule Mailer do
  use Bamboo.Mailer, otp_app: :bamboo_unisender
end

defmodule PoC do
  import Bamboo.Email

  def run(params) do
    email = new_email(
      to: "ssnikolay@gmail.com",
      from: {"Nikolay", "mailer@voltmobi.com"},
      subject: "Unisender",
      html_body: "<p>Unisender!</p>"
    )
    email |> Mailer.deliver_now
  end
end

IO.puts PoC.run(%{})
