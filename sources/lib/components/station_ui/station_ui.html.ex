defmodule StationUI.HTML do
  defmacro __using__(_) do
    quote do
      import StationUI.HTML.{
        Avatar,
        Banner,
        Button,
        Accordion,
        Card,
        Footer,
        Form,
        Icon,
        LegacyCoreComponents,
        NotificationBadge,
        Input,
        Modal,
        Navbar,
        Pagination,
        Spinner,
        StatusBadge,
        TabGroup,
        Tag,
        Toast,
        Toolbar,
        Tooltip,
        TableHeader,
        TableCell
      }
    end
  end
end
