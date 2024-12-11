import gleam/string
import wisp

pub fn get(_req: wisp.Request, path: List(String)) -> wisp.Response {
  let path = string.join(path, "/")
  wisp.ok() |> wisp.string_body("static path: " <> path)
}
