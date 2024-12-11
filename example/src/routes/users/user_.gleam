import gleam/int
import gleam/list
import gleam/string
import gleam/string_builder
import routes/users/index
import wisp

pub fn get(_req: wisp.Request, name: String) -> wisp.Response {
  case
    index.users
    |> list.find(fn(user) {
      user.0 |> string.lowercase == name |> string.lowercase
    })
  {
    Ok(user) ->
      {
        "This is "
        <> user.0
        <> ", "
        <> {
          case user.1 {
            "m" -> "he is "
            "w" -> "she is "
            _ -> "they are "
          }
        }
        <> { user.2 |> int.to_string }
        <> " years old."
      }
      |> string_builder.from_string
      |> wisp.html_response(200)
    Error(_) -> wisp.not_found()
  }
}

pub fn delete(_req: wisp.Request, _age: Int) -> wisp.Response {
  todo
}
