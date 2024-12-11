import gleam/erlang/process
import mist
import wisp
import wisp/wisp_mist

import router.{route}

pub fn main() {
  wisp.configure_logger()

  let assert Ok(_) =
    wisp_mist.handler(route, wisp.random_string(10))
    |> mist.new
    |> mist.port(3000)
    |> mist.start_http

  process.sleep_forever()
}
