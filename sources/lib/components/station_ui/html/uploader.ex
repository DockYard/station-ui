defmodule StationUI.HTML.Uploader do
  use Phoenix.Component

  import StationUI.HTML.Icon, only: [icon: 1]

  alias Phoenix.LiveView.JS

  @doc ~S"""
  The uploader component renders a LiveView uploader that accepts file input either via
  drag-and-drop or via file browsing.

  Example usage:

  ```
  <.uploader
    id="image-upload"
    save_fn={&save_fn/2}
    accept={~w(image/*)}
    max_entries={4}
    class="mt-8"
  >
    <:support>
      Support Text
    </:support>
  </.uploader>
  ```

  where save_fn/2 is defined in the LiveView that is invoking the uploader. save_fn/2 must be
  a function that takes two arguments, `%{path: path}, entry`, where `path` is the path to the
  incoming file, and `entry` is the LiveView.UploadEntry. The function must return
  `{:ok, uploaded_path}`. `uploaded_path` should be the filename, or the relative or absolute
  path to the uploaded file, although it can be any string.

  Example implementation of save_fn:

  ```
  fn %{path: path}, entry ->
    # For this example function to work, you will need to create the `priv/static/uploads`
    # directory.
    # Also, in order to link to your upload, for example in an <img> tag or a verified
    # route, you need to add the uploads directory to `static_paths/0`. In a vanilla
    # Phoenix project, `static_paths/0` is found in lib/my_app_web.ex.
    # Also, replace `:my_app` with the name of your app.
    dest =
      Path.join([
        :code.priv_dir(:my_app),
        "static",
        "uploads",
        Path.basename(entry.client_name)
      ])

    File.cp!(path, dest)

    {:ok, ~p"/uploads/#{Path.basename(dest)}"}
  end
  ```
  """

  attr :id, :string,
    default: "uploader-component",
    doc: "Unique id is required if more than one upload component is on a single page."

  attr :save_fn, :any,
    required: true,
    doc:
      "Function that takes two arguments, `%{path: path}, entry`, where `path` is the path to the incoming file, and `entry` is the LiveView.UploadEntry. It must return `{:ok, uploaded_path}`. `uploaded_path` should be the relative or absolute path to the uploaded file, although it can be any string."

  attr :accept, :any,
    default: :any,
    doc:
      "List of file extensions or mime types to allow to be uploaded, such as ~w(.jpg .jpeg) or ~w(image/*). You may also pass the atom :any instead of a list to allow any kind of file to be uploaded."

  attr :max_entries, :integer,
    default: 1,
    doc: "Maximum number of files that can be uploaded at once."

  attr :class, :string, default: ""

  slot :support, doc: "Explanatory content directly below the uploader."

  def uploader(assigns) do
    ~H"""
    <.live_component module={__MODULE__.LiveComponent} {assigns} />
    """
  end

  # Do not use directly; use `Uploader.uploader/1` component instead.
  defmodule LiveComponent do
    @moduledoc false

    use Phoenix.LiveComponent

    @impl true
    def update(assigns, socket) do
      {:ok,
       socket
       |> assign(assigns)
       |> assign(:uploaded_files, [])
       |> allow_upload(:files, accept: assigns.accept, max_entries: assigns.max_entries)}
    end

    @impl true
    def render(assigns) do
      ~H"""
      <div>
        <form id={@id} phx-submit="save" phx-change="validate" phx-target={@myself}>
          <div
            class={[
              "border-dashed border-2 border-[--sui-brand-primary-text] rounded-lg py-14",
              @class
            ]}
            phx-drop-target={@uploads.files.ref}
          >
            <section>
              <div class="flex h-full flex-col flex-wrap items-center justify-center gap-1.5">
                <span class="flex">
                  <.live_file_input class="hidden" upload={@uploads.files} />
                  <.icon name="hero-cloud-arrow-up-solid" class="text-[--sui-brand-primary] mr-1.5 h-6 w-6 shrink-0" />
                  <p class="text-base">Drag and Drop your Files here</p>
                </span>
                <p class="text-base">or</p>
                <button
                  class="sui-primary [:where(&)]:rounded-lg [:where(&)]:text-base py-[7px] text-[--sui-brand-primary] inline-flex items-center justify-center gap-x-1.5 whitespace-nowrap px-2 font-bold focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-purple-500 lg:gap-x-2 relative hover:underline hover:decoration-2 hover:underline-offset-4 focus-visible:underline focus-visible:decoration-2 focus-visible:underline-offset-4 bg-indigo-700 text-white"
                  type="button"
                  phx-click={JS.dispatch("click", to: "##{@uploads.files.ref}")}
                >
                  Browse Files
                </button>
              </div>
            </section>
          </div>

          <p :for={support <- @support}>{render_slot(support)}</p>

          <div class="mt-4">
            <article :for={entry <- @uploads.files.entries} class="upload-entry">
              <h3 class="max-w-[700px] flex w-full">
                {entry.client_name}
                <button class="ml-auto" type="button" phx-click="cancel-upload" phx-value-ref={entry.ref} phx-target={@myself} aria-label="cancel">
                  <.icon name="hero-trash-solid" />
                </button>
              </h3>
              <p class="text-gray-500">{humanize_file_size(entry.client_size)}</p>
              <p :for={err <- upload_errors(@uploads.files, entry)} class="alert alert-danger text-red-500">
                {error_to_string(err, assigns)}
              </p>

              <label>
                <span class="sr-only">Upload progress</span>
                <progress class="min-w-full rounded-full bg-blue-200 text-blue-700" value={entry.progress} max="100">
                  {entry.progress}%
                </progress>
              </label>
            </article>

            <p :for={err <- upload_errors(@uploads.files)} class="alert alert-danger mt-4 text-red-500">
              {error_to_string(err, assigns)}
            </p>
            <button
              :if={Enum.any?(@uploads.files.entries)}
              class="sui-primary [:where(&)]:rounded-lg [:where(&)]:text-base py-[7px] text-[--sui-brand-primary] inline-flex items-center justify-center gap-x-1.5 whitespace-nowrap px-2 font-bold focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-purple-500 lg:gap-x-2 relative hover:text-blue-500 hover:underline hover:decoration-2 hover:underline-offset-4 focus-visible:text-blue-500 focus-visible:underline focus-visible:decoration-2 focus-visible:underline-offset-4"
              type="submit"
            >
              Upload
            </button>
          </div>
        </form>

        <div :if={Enum.any?(@uploaded_files)}>
          <h3>Uploaded files</h3>
          <ul>
            <li :for={{filename, size} <- @uploaded_files}>
              <.icon name="hero-check-circle-solid" class="text-[--sui-brand-primary-success] mr-2 h-4 w-4" />
              {filename}
              <br />
              <span class="pl-8 text-gray-500">{humanize_file_size(size)}</span>
            </li>
          </ul>
        </div>
      </div>
      """
    end

    @impl true
    def handle_event("validate", _params, socket) do
      {:noreply, socket}
    end

    @impl true
    def handle_event("cancel-upload", %{"ref" => ref}, socket) do
      {:noreply, cancel_upload(socket, :files, ref)}
    end

    @impl true
    def handle_event("save", _params, socket) do
      uploaded_filenames =
        consume_uploaded_entries(socket, :files, socket.assigns.save_fn)
        |> Enum.map(&Path.basename(&1))

      # This reverses the list `uploaded_filenames`, which happens to be good because
      # it fixes the fact that Phoenix.LiveView.Upload.consume_entries() already reversed
      # the list of uploads.
      # Rather than reverse the entries' sizes to match, which would be a brittle hack,
      # we'll look up the uploads by name in the socket.assigns.uploads.files.entries
      # list to get the size of each.
      uploaded_files =
        Enum.reduce(
          uploaded_filenames,
          [],
          fn filename, acc ->
            size =
              socket.assigns.uploads.files.entries
              |> Enum.find_value(&if &1.client_name == filename, do: &1.client_size)

            [{filename, size} | acc]
          end
        )

      {:noreply, update(socket, :uploaded_files, &(&1 ++ uploaded_files))}
    end

    defp error_to_string(:too_large, _), do: "This file is too large"

    defp error_to_string(:not_accepted, %{accept: accept}),
      do: "This file is not of file type #{accept}."

    defp error_to_string(:too_many_files, %{max_entries: max_entries}),
      do: "You have selected too many files. Maximum of #{max_entries} files."

    # The uploader doesn't seem to accept files > several MB.
    defp humanize_file_size(size) do
      if size > 1_000_000 do
        "#{Float.round(size / 1_000_000, 1)} MB"
      else
        if size > 1_000 do
          "#{Float.round(size / 1_000, 1)} kB"
        else
          "#{round(size)} B"
        end
      end
    end
  end
end
