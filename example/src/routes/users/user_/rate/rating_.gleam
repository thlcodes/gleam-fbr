import gleam/io
import wisp

pub fn get(_req: wisp.Request, name: String, rating: String) -> wisp.Response {
  io.println("rated user " <> name <> " with " <> rating)
  wisp.no_content()
}

// ignored since not public
fn post(_req: wisp.Request, name: String) -> wisp.Response {
  todo
}
