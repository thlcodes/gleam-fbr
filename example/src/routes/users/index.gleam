import gleam/list
import gleam/string
import gleam/string_builder
import wisp

pub const users = [#("John", "m", 26), #("Jen", "w", 34), #("Ida", "d", 52)]

pub fn get(_req: wisp.Request) -> wisp.Response {
  {
    "<ul>"
    <> users
    |> list.map(fn(user) {
      "<li><a href=\""
      <> { user.0 |> string.lowercase }
      <> "\">"
      <> user.0
      <> "</a>"
    })
    |> string.join("")
    <> "</ul>"
  }
  |> string_builder.from_string
  |> wisp.html_response(200)
}

// invalid put since no req as param
pub fn put() -> wisp.Response {
  wisp.ok()
}

// invalid post since not response return
pub fn post(_req: wisp.Request) {
  wisp.ok()
}
