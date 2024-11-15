# StationUI

Station UI is a [design system](https://www.figma.com/community/file/1338983767724300048) and component library built by DockYard to accelerate product development. Built on Elixir/Phoenix and TailwindCSS, the components were designed with extensibility in mind. You can use them as is in order to ship features quickly, or customize their functionality and styling without ever feeling locked in.

In addition to these benefits, Station UI also replaces Phoenix Core Components. Station UI makes this seamless by including a compatibility layer with the same API as Phoenix Core Components, allowing the generators in the phoenix ecosystem (live, auth, etc.) to render with Station UI components without any changes to the generated code.

## Installing Station UI

### From Repo

1. Add `{:station_ui, github: "dockyard/station-ui"}` to your deps in `mix.exs`
1. Inside your project root, run `mix station_ui.install`.
