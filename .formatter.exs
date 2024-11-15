# Used by "mix format"
[
  import_deps: [:phoenix],
  plugins: [TailwindFormatter, Phoenix.LiveView.HTMLFormatter],
  inputs: [
    "{mix,.formatter}.exs",
    "{lib,sources,test}/**/*.{ex,exs}"
  ],
  line_length: 150
]
