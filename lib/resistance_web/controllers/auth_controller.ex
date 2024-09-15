defmodule ResistanceWeb.AuthController do
  use ResistanceWeb, :controller
  plug Ueberauth

  alias Resistance.Users
  alias ResistanceWeb.UserAuth

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    user_data = %{token: auth.credentials.token, provider: "github", email: auth.info.email}

    if user = Users.get_user_by_email(auth.info.email) do
      if user.provider == "github" do
        conn
        |> put_flash(:info, "Login successful!")
        |> UserAuth.log_in_user(user, user_data)
      else
        conn
        |> put_flash(:error, "This account is already registered!")
        |> redirect(to: ~p"/users/log_in")
      end
    else
      {:ok, user} = Users.register_oauth_user(user_data)

      conn
      |> put_flash(:info, "Login successful!")
      |> UserAuth.log_in_user(user, user_data)
    end
  end
end
