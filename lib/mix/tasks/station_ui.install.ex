defmodule Mix.Tasks.StationUi.Install do
  use Mix.Task

  defmodule PathContext do
    defstruct [:app_root_path, :web_path, :web_app_name, :web_assets_path, :umbrella]

    @assets_subpath "assets"

    @station_ui_subpath "components/station_ui"

    @sources_root_path __DIR__ |> Path.join("../../../sources") |> Path.expand()

    def create([]) do
      create([File.cwd!()])
    end

    def create([app_root_path | _]) do
      app_root_path = Path.expand(app_root_path)

      if File.exists?(app_root_path) do
        %__MODULE__{
          app_root_path: app_root_path,
          umbrella: umbrella?(app_root_path)
        }
        |> find_web_path()
        |> then(&{:ok, &1})
      else
        {:error, "Folder `#{app_root_path}` does not exist"}
      end
    end

    defp umbrella?(app_root_path) do
      case File.ls(Path.join(app_root_path, "apps")) do
        {:ok, _apps} -> true
        _ -> false
      end
    end

    def web_app_ex_path(%PathContext{} = context) do
      snake_web_app = Macro.underscore(context.web_app_name)

      Path.join(context.web_path, "../#{snake_web_app}.ex")
    end

    defp find_web_path(%__MODULE__{web_path: nil} = context) do
      web_path = web_path(context.app_root_path)

      web_app_name = Macro.camelize(Path.basename(web_path))

      maybe_web_assets_path =
        web_path
        |> Path.join("../..")
        |> Path.join(@assets_subpath)
        |> Path.expand()

      web_assets_path =
        if File.exists?(maybe_web_assets_path) do
          maybe_web_assets_path
        end

      %{
        context
        | web_path: web_path,
          web_app_name: web_app_name,
          web_assets_path: web_assets_path
      }
    end

    defp web_path(app_root_path) do
      apps_path = Path.join(app_root_path, "apps")
      lib_path = Path.join(app_root_path, "lib")
      apps_ls = File.ls(apps_path)
      lib_ls = File.ls(lib_path)

      case {apps_ls, lib_ls} do
        {{:ok, apps}, _} ->
          find_web_path_child(apps, apps_path) |> add_lib()

        {_, {:ok, apps}} ->
          find_web_path_child(apps, lib_path)

        _ ->
          raise "No apps or lib folder found. Please run this from the root of your project or specify the path"
      end
    end

    defp find_web_path_child([], path), do: raise("_web file not found in #{path}")

    defp find_web_path_child([hd | tl], path) do
      if String.ends_with?(hd, "_web") do
        Path.join(path, hd)
      else
        find_web_path_child(tl, path)
      end
    end

    defp add_lib(path) do
      Path.join([path, "lib", Path.basename(path)])
    end

    def sources_to_copy(%__MODULE__{} = context) do
      template_sources =
        @sources_root_path
        |> Path.join("lib")
        |> Path.join("**/*.*")
        |> Path.wildcard()
        |> Enum.map(&{&1, template_source_destination_file_path(context, &1), true})

      js_sources =
        @sources_root_path
        |> Path.join("js")
        |> Path.join("**/*.*")
        |> Path.wildcard()
        |> Enum.map(&{&1, asset_source_destination_file_path(context, &1), false})

      css_sources =
        @sources_root_path
        |> Path.join("css")
        |> Path.join("**/*.*")
        |> Path.wildcard()
        |> Enum.map(&{&1, asset_source_destination_file_path(context, &1), false})

      font_sources =
        @sources_root_path
        |> Path.join("static/fonts")
        |> Path.join("**/*.*")
        |> Path.wildcard()
        |> Enum.map(&{&1, font_source_destination_file_path(context, &1), false})

      template_sources ++ js_sources ++ css_sources ++ font_sources
    end

    defp template_source_destination_file_path(context, source_file_path) do
      installer_lib = Path.join(@sources_root_path, "lib/components/station_ui")
      relative_source_path = Path.relative_to(source_file_path, installer_lib)

      Path.join([context.web_path, @station_ui_subpath, relative_source_path])
    end

    defp asset_source_destination_file_path(context, source_file_path) do
      Path.join(
        context.web_assets_path,
        Path.relative_to(source_file_path, @sources_root_path)
      )
    end

    defp font_source_destination_file_path(context, source_file_path) do
      Path.join([
        context.web_assets_path,
        "../priv",
        Path.relative_to(source_file_path, @sources_root_path)
      ])
    end
  end

  def run(args) do
    dry_run = Enum.any?(args, &(&1 == "--dry-run"))

    Mix.shell().info("Running StationUI Installer")

    {:ok, %PathContext{} = context} = PathContext.create(args)

    Mix.shell().info("Running for #{context.web_app_name} found at path: #{context.web_path}")

    for {source_path, dest_path, template} <- PathContext.sources_to_copy(context) do
      binary = File.read!(source_path)

      binary =
        if template do
          binary
          |> String.replace("StationUI.HTML", "#{context.web_app_name}.StationUI.HTML")
          |> String.replace("StationUI.Gettext", "#{context.web_app_name}.Gettext")
        else
          binary
        end

      Mix.shell().info("Writing #{dest_path} #{if dry_run, do: "(dry run)"}")

      if not dry_run do
        File.mkdir_p!(Path.dirname(dest_path))
        File.write!(dest_path, binary)
      end
    end

    tailwind_config_path = Path.join(context.web_assets_path, "tailwind.config.js")
    tailwind_content = File.read!(tailwind_config_path)
    module_exports_line = ~s|module.exports = {\n|
    sui_preset = "  presets: [\n    require('./js/station-ui.js'),\n  ],\n"

    tailwind_content =
      String.replace(tailwind_content, module_exports_line, module_exports_line <> sui_preset)

    File.write!(tailwind_config_path, tailwind_content)
    Mix.shell().info("Updated #{tailwind_config_path}")

    app_css_path = Path.join(context.web_assets_path, "css/app.css")
    app_css_content = File.read!(app_css_path)

    File.write!(
      app_css_path,
      ~s|@import "./station-ui.css";\n@import "./station-ui-fonts.css";\n| <> app_css_content
    )

    Mix.shell().info("Updated #{app_css_path}")

    web_app_ex_path = PathContext.web_app_ex_path(context)
    web_app_ex_content = File.read!(web_app_ex_path)
    core_components_import = "import #{context.web_app_name}.CoreComponents"

    web_app_ex_content =
      String.replace(
        web_app_ex_content,
        core_components_import,
        "# #{core_components_import}\n      use #{context.web_app_name}.StationUI.HTML"
      )

    File.write!(web_app_ex_path, web_app_ex_content)
    Mix.shell().info("Updated #{web_app_ex_path}")

    if Mix.shell().yes?(
         "StationUI is designed to replace the default Phoenix CoreComponents. Ok to clear out the existing CoreComponents file? Unless you made custom changes to this file that you still want, this should be fine to do."
       ) do
      core_components_path = Path.join(context.web_path, "components/core_components.ex")
      [first | rest] = File.read!(core_components_path) |> String.trim() |> String.split("\n")
      last = List.last(rest)
      File.rm!(core_components_path)

      File.write(
        core_components_path,
        Enum.join([first, "  # Replaced by StationUI components, do not remove or phoenix generators will recreate the full file", last], "\n")
      )

      Mix.shell().info("Replaced #{core_components_path}")
    else
      Mix.shell().info("Skipping replacing CoreComponents")
    end
  end
end
