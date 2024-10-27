import wisp

pub fn get(_req: wisp.Request, path: String) -> wisp.Response {
  wisp.ok() |> wisp.string_body("static path: " <> path)
}
