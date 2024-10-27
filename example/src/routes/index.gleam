import gleam/string_builder
import wisp

pub fn get(_req: wisp.Request) -> wisp.Response {
  "hi from index" |> string_builder.from_string |> wisp.html_response(200)
}
