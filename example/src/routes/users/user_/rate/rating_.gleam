import context
import gleam/io
import gleam/string
import wisp

pub fn get(
  _req: wisp.Request,
  _ctx: context.Context,
  name: String,
  rating: String,
) -> wisp.Response {
  io.println("rated user " <> name <> " with " <> rating)
  wisp.redirect("/users/" <> string.lowercase(name))
}

// ignored since not public
fn post(_req: wisp.Request, name: String) -> wisp.Response {
  todo
}
