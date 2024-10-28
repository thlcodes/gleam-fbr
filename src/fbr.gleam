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
import generator.{generate}
import parser.{parse_route_files}
import types.{type Route, InvalidRoute, Route, route_to_string}

pub fn main() {
  case
    {
      use cwd <- result.try(get_cwd())
      use files <- result.try(get_route_files(cwd))
      use routes <- result.try(parse_route_files(files))
      let #(valid_routes, invalid_routes) = group_routes(routes)

      print_routes(valid_routes, invalid_routes)

      use content <- result.try(generate(
        valid_routes,
        cwd <> consts.router_file,
      ))

      Ok(content)
    }
  {
    Ok(content) -> {
      io.println("\n######################\n" <> content)

      Nil
    }
    Error(err) -> snag.pretty_print(err) |> io.println_error
  }
}

fn print_routes(valid: List(Route), invalid: List(Route)) {
  io.println("Found the following valid routes:")
  list.map(valid, fn(route) { route_to_string(route) |> io.println })

  io.println("")
  io.println_error("Found the following invalid routes:")
  list.map(invalid, fn(route) { route_to_string(route) |> io.println_error })
}

fn group_routes(routes: List(Route)) -> #(List(Route), List(Route)) {
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
  #(valid_routes, invalid_routes)
}

fn get_cwd() -> Result(String) {
  simplifile.current_directory()
  |> map_file_error("could not get current directory")
}

fn get_route_files(cwd: String) -> Result(List(String)) {
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
