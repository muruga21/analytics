defmodule PlausibleWeb.Live.PropsSettings do
  @moduledoc """
  LiveView allowing listing, allowing and disallowing custom event properties.
  """

  use Phoenix.LiveView
  use Phoenix.HTML
  alias PlausibleWeb.Live.Components.ComboBox

  def mount(
        _params,
        %{"site_id" => site_id, "domain" => domain, "current_user_id" => user_id},
        socket
      ) do
    socket =
      socket
      |> assign_new(:site, fn ->
        Plausible.Sites.get_for_user!(user_id, domain, [:owner, :admin, :super_admin])
      end)
      |> assign_new(:all_props, fn %{site: site} ->
        site.allowed_event_props || []
      end)
      |> assign_new(:displayed_props, fn %{all_props: props} ->
        props
      end)

    {:ok,
     assign(socket,
       site_id: site_id,
       domain: domain,
       current_user_id: user_id,
       add_prop?: false,
       filter_text: ""
     )}
  end

  def render(assigns) do
    ~H"""
    <section id="props-settings-main">
      <.live_component id="embedded_liveview_flash" module={PlausibleWeb.Live.Flash} flash={@flash} />
      <%= if @add_prop? do %>
        <%= live_render(
          @socket,
          PlausibleWeb.Live.PropsSettings.Form,
          id: "props-form",
          session: %{
            "current_user_id" => @current_user_id,
            "domain" => @domain,
            "site_id" => @site_id,
            "rendered_by" => self()
          }
        ) %>
      <% end %>

      <.live_component
        module={PlausibleWeb.Live.PropsSettings.List}
        id="props-list"
        props={@displayed_props}
        domain={@domain}
        filter_text={@filter_text}
      />
    </section>
    """
  end

  def handle_event("allow", %{"prop" => prop}, socket) do
    case Plausible.Props.allow(socket.assigns.site, prop) do
      {:ok, site} ->
        send_update(ComboBox, id: :prop_input, display_value: "", submit_value: "")

        {:noreply,
         assign(socket,
           site: site,
           form: new_form(site)
         )}

      {:error, changeset} ->
        {:noreply,
         assign(socket,
           form: to_form(Map.put(changeset, :action, :validate))
         )}
    end
  end

  def handle_event("add-prop", _value, socket) do
    {:noreply, assign(socket, add_prop?: true)}
  end

  def handle_event("filter", %{"filter-text" => filter_text}, socket) do
    new_list =
      ComboBox.StaticSearch.suggest(
        filter_text,
        socket.assigns.all_props
      )

    {:noreply, assign(socket, displayed_props: new_list, filter_text: filter_text)}
  end

  def handle_event("reset-filter-text", _params, socket) do
    {:noreply, assign(socket, filter_text: "", displayed_props: socket.assigns.all_props)}
  end

  def handle_event("disallow-prop", %{"prop" => prop}, socket) do
    {:ok, site} = Plausible.Props.disallow(socket.assigns.site, prop)

    socket =
      socket
      |> put_flash(:success, "Property removed successfully")
      |> assign(
        all_props: Enum.reject(socket.assigns.all_props, &(&1 == prop)),
        displayed_props: Enum.reject(socket.assigns.displayed_props, &(&1 == prop)),
        site: site
      )

    Process.send_after(self(), :clear_flash, 5000)
    {:noreply, socket}
  end

  def handle_event("allow-existing-props", _params, socket) do
    {:ok, site} = Plausible.Props.allow_existing_props(socket.assigns.site)

    {:noreply,
     assign(socket,
       site: site
     )}
  end

  def handle_info(:cancel_add_prop, socket) do
    {:noreply, assign(socket, add_prop?: false)}
  end

  def handle_info({:props_allowed, props}, socket) when is_list(props) do
    socket =
      socket
      |> assign(
        add_prop?: false,
        filter_text: "",
        all_props: props,
        displayed_props: props
      )
      |> put_flash(:success, "Properties added successfully")

    {:noreply, socket}
  end

  def handle_info({:prop_allowed, prop}, socket) when is_binary(prop) do
    socket =
      socket
      |> assign(
        add_prop?: false,
        filter_text: "",
        all_props: [prop | socket.assigns.all_props],
        displayed_props: [prop | socket.assigns.all_props]
      )
      |> put_flash(:success, "Property added successfully")

    {:noreply, socket}
  end

  def handle_info(:clear_flash, socket) do
    {:noreply, clear_flash(socket)}
  end

  defp new_form(site) do
    to_form(Plausible.Props.allow_changeset(site, []))
  end
end
