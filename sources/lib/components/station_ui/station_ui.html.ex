defmodule StationUI.HTML do
  defmacro __using__(_) do
    quote do
      import StationUI.HTML.{
        Avatars,
        Banners,
        Buttons,
        Accordion,
        Cards,
        Footer,
        Forms,
        Icons,
        LegacyCoreComponents,
        NotificationBadges,
        Inputs,
        Modals,
        Navbar,
        Pagination,
        Spinners,
        StatusBadges,
        TabGroup,
        Tags,
        Toast,
        Toolbars,
        Tooltips,
        TableHeader,
        TableCell
      }
    end
  end
end
