import context.{type Context}
import gleam/list
import gleam/string_builder
import wisp

pub fn get(req: wisp.Request, ctx: Context) -> wisp.Response {
  let joke = case wisp.get_cookie(req, "joke", wisp.PlainText) {
    Ok(joke) -> joke
    _ -> ctx.default_joke
  }

  { "<q>" <> joke <> "</q>
  <form method=\"post\" action=\"/joke\">
    <input type=\"text\" placeholder=\"new joke\" name=\"joke\" />
    <button type=\"submit\">Send</button>
  </form>" }
  |> string_builder.from_string
  |> wisp.html_response(200)
}

pub fn post(req: wisp.Request) -> wisp.Response {
  use form <- wisp.require_form(req)
  let assert Ok(joke) = list.key_find(form.values, "joke")

  wisp.redirect("/joke")
  |> wisp.set_cookie(req, "joke", joke, wisp.PlainText, 60 * 60)
}

// invalid since to many params
pub fn put(_req: wisp.Request, _name: String) -> wisp.Response {
  wisp.unprocessable_entity()
}
