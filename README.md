# SmartWebsocketClient

`SmartWebsocketClient` is a (not-so) smart websocket client with pool support.

The main goal of this library is to provide a simple interface to send and receive websocket messages. Have in mind that this is only a *client*, if you want a *server* take a look at [Cowboy](https://github.com/ninenines/cowboy). There is a simple implementation of a websocket server at `test/helper/server.ex`, which is a helper to test the client.

The client will spawn two processes for each socket. One is responsible for saving the socket state in a pool, and the other listens for new messages.

## Pool

SWC adds support for pools through [poolboy](https://github.com/devinus/poolboy) (hopefully a twink?). If you do not specify a pool (i.e. you want only one websocket connection), then a pool of one connection is created. Take a look at `SmartWebsocketClient.Pool` for details.

## Usage

Connecting and sending/receiving messages is very straightforward. Here's an example:

```elixir
  defmodule MyClient do
    alias SmartWebsocketClient.{Connection, Pool}

    def run do
      connection = %Connection{host: "127.0.0.1", port: 80, path: "/"}
      pool = %Pool{size: 10, overflow: 5}
      SmartWebsocketClient.connect(connection, MyListener, pool)
      SmartWebsocketClient.send("My message")

      # If you don't want to run the client forever, uncomment the line below
      #SmartWebsocketClient.disconnect()
    end
  end

  defmodule MyListener do
    use SmartWebsocketClient.Listener

    def on_receive(msg) do
      IO.puts "Message received!"
      IO.inspect msg
    end
  end
```

The above example gives an idea of the library's interface. You don't need to specify a pool if you do not want one.

## Listener

The `SmartWebsocketClient.Listener` is a behaviour that allows you to act on received messages. It has a very simple interface, as you can see in the example. 

As a behaviour, you are required to implement the `c:SmartWebsocketClient.Listener.on_receive/1` callback. You can also extend the behaviour to better suit your needs. Take a look at `SmartWebsocketClient.Listener` for details.

The default Listener behaviour automatically handles ping messages.

# Enhancements / TODO

- [] Add interaction between Listener and GenServer, so the GenServer behind Listener is non-blocking and can handle different messages
- [] Currently only one SWC can be run per node. Make SWC use only PIDs (instead of registered names) and support multiple clients per node.
