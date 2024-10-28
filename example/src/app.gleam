import gleam/erlang/process
import mist
import wisp
import wisp/wisp_mist

import router.{router}

pub fn main() {
  wisp.configure_logger()

  let assert Ok(_) =
    wisp_mist.handler(router, wisp.random_string(10))
    |> mist.new
    |> mist.port(3000)
    |> mist.start_http

  process.sleep_forever()
}
