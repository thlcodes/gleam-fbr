import gleam/string_builder
import wisp

const default_joke = "this is supposed to be a joke"

pub fn get(req: wisp.Request) -> wisp.Response {
  case wisp.get_cookie(req, "joke", wisp.PlainText) {
    Ok(joke) -> joke
    _ -> default_joke
  }
  |> string_builder.from_string
  |> wisp.html_response(200)
}

pub fn post(req: wisp.Request) -> wisp.Response {
  use body <- wisp.require_string_body(req)
  wisp.ok() |> wisp.set_cookie(req, "joke", body, wisp.PlainText, 60 * 60)
}

// invalid since to many params
pub fn put(_req: wisp.Request, _name: String) -> wisp.Response {
  wisp.unprocessable_entity()
}
