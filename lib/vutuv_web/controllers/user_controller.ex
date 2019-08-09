defmodule VutuvWeb.UserController do
  use VutuvWeb, :controller

  import VutuvWeb.AuthorizeConn

  alias Phauxth.Log
  alias Vutuv.{Accounts, Accounts.User, Socials}
  alias VutuvWeb.{Auth.Otp, Email}

  @dialyzer {:nowarn_function, new: 3}

  def action(conn, _) do
    if action_name(conn) in [:index, :new, :create, :show] do
      apply(__MODULE__, action_name(conn), [conn, conn.params, conn.assigns.current_user])
    else
      auth_action_slug(conn, __MODULE__)
    end
  end

  def index(conn, params, _current_user) do
    page = Accounts.paginate_users(params)
    render(conn, "index.html", users: page.entries, page: page)
  end

  def new(conn, _, %User{} = user) do
    redirect(conn, to: Routes.user_path(conn, :show, user))
  end

  def new(conn, _, _current_user) do
    changeset = Accounts.change_user(%User{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"user" => user_params}, _current_user) do
    user_params =
      conn |> get_req_header("accept-language") |> add_accept_language_to_params(user_params)

    case Accounts.create_user(user_params) do
      {:ok, user} ->
        Log.info(%Log{user: user.id, message: "user created"})
        email = user_params["email"]
        user_credential = Accounts.get_user_credential(%{"email" => email})
        code = Otp.create(user_credential.otp_secret)
        Email.verify_request(email, code)

        conn
        |> put_flash(:info, "User created successfully.")
        |> redirect(to: Routes.verification_path(conn, :new, email: email))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"slug" => slug}, %{"slug" => slug} = current_user) do
    user =
      Accounts.with_associated_data(current_user, [:email_addresses, :tags, :followers, :leaders])

    posts = Socials.list_posts(current_user)
    render(conn, "show.html", user: user, posts: posts)
  end

  def show(conn, %{"slug" => slug}, current_user) do
    user = Accounts.get_user!(%{"slug" => slug})
    user = Accounts.with_associated_data(user, [:email_addresses, :tags, :followers, :leaders])
    posts = Socials.list_posts(user, current_user)
    render(conn, "show.html", user: user, posts: posts)
  end

  def edit(conn, _, user) do
    changeset = Accounts.change_user(user)
    render(conn, "edit.html", user: user, changeset: changeset)
  end

  def update(conn, %{"user" => user_params}, user) do
    case Accounts.update_user(user, user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "User updated successfully.")
        |> redirect(to: Routes.user_path(conn, :show, user))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", user: user, changeset: changeset)
    end
  end

  def delete(conn, _, user) do
    {:ok, _user} = Accounts.delete_user(user)

    conn
    |> delete_session(:phauxth_session_id)
    |> put_flash(:info, "User deleted successfully.")
    |> redirect(to: Routes.session_path(conn, :new))
  end

  defp add_accept_language_to_params(accept_language, %{"user" => _} = user_params) do
    al = if accept_language == [], do: "", else: hd(accept_language)
    put_in(user_params, ["user", "accept_language"], al)
  end

  defp add_accept_language_to_params(_, user_params), do: user_params
end
