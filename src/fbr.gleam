import gleam/dict
import gleam/io
import gleam/list
import gleam/order
import gleam/result
import gleam/string
import simplifile
import snag.{type Result}

import consts.{routes_folder}
import errors.{map_file_error}
import parser.{parse_route_files}
import types.{type Route, InvalidRoute, Route, route_to_string}

pub fn main() {
  case
    {
      use files <- result.try(get_route_files())
      use routes <- result.try(parse_route_files(files))

      Ok(routes)
    }
  {
    Error(err) -> snag.pretty_print(err) |> io.println_error
    Ok(routes) -> {
      let grouped =
        routes
        |> list.group(fn(route) {
          case route {
            InvalidRoute(..) -> "invalid"
            Route(..) -> "valid"
          }
        })
      let valid_routes =
        dict.get(grouped, "valid")
        |> result.unwrap([])
        |> sort_routes
      let invalid_routes = dict.get(grouped, "invalid") |> result.unwrap([])

      io.println("Found the following valid routes:")
      list.map(valid_routes, fn(route) { route_to_string(route) |> io.println })

      io.println("")
      io.println_error("Found the following invalid routes:")
      list.map(invalid_routes, fn(route) {
        route_to_string(route) |> io.println_error
      })

      Nil
    }
  }
}

fn get_route_files() -> Result(List(String)) {
  use cwd <- result.try(
    simplifile.current_directory()
    |> map_file_error("could not get current directory"),
  )

  let routes_dir = cwd <> routes_folder

  use files <- result.try(
    simplifile.get_files(routes_dir)
    |> map_file_error("could not list files"),
  )

  files
  |> list.filter(fn(file) { file |> string.ends_with(".gleam") })
  |> list.map(fn(file) { file |> string.drop_left(string.length(cwd) + 1) })
  |> Ok
}

fn sort_routes(routes: List(Route)) -> List(Route) {
  routes
  |> list.sort(fn(a, b) {
    case a, b {
      Route(_, _, _, path_a), Route(_, _, _, path_b) ->
        case list.length(path_a), list.length(path_b) {
          _ as la, _ as lb if la > lb -> order.Gt
          _ as la, _ as lb if la < lb -> order.Lt
          _ as la, _ as lb if la == lb -> order.Eq
          _, _ -> order.Eq
        }
      _, _ -> order.Eq
    }
  })
}
