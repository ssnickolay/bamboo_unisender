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
      html_body: "<p>Unisender!</p>",
      assigns: %{list_id: 10513637}
      # attachments: [Bamboo.Attachment.new("/Users/ssnickolay/Documents/piki.jpg")]
    )
    email |> Mailer.deliver_now
  end
end

IO.puts PoC.run(%{})
