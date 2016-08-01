defmodule AllowanceTest do
  use ExUnit.Case
  doctest Allowance

  test "creating an allowance" do
    assert {{<<>>, nil}, 0} = Allowance.new(nil, 0)
  end

  test "adding tokens" do
    assert {{<<>>, nil}, 100} =
      Allowance.new(nil, 0)
      |> Allowance.add_tokens(100)

    assert {{<<>>, nil}, 150} =
      Allowance.new(nil, 50)
      |> Allowance.add_tokens(100)
  end

  test "setting tokens" do
    assert {{<<>>, nil}, 100} =
      Allowance.new(nil, 25)
      |> Allowance.set_tokens(100)

    assert {{<<>>, nil}, 0} =
      Allowance.new(nil, 50)
      |> Allowance.set_tokens(0)
  end

  describe "taking tokens" do
    test "more than available tokens" do
      assert {100, {{<<>>, 200}, 0}} =
        Allowance.new(200, 100)
        |> Allowance.take_tokens(200)
    end

    test "less than remaining" do
      assert {20, {{<<>>, 200}, 180}} =
        Allowance.new(200, 200)
        |> Allowance.take_tokens(20)
    end

    test "more than remaining" do
      assert {20, {{<<>>, 20}, 0}} =
        Allowance.new(20, 20)
        |> Allowance.take_tokens(100)
    end
  end

  test "writing data to a buffer" do
    data = "foobar"
    assert {:ok, {{^data, 94}, 0}} =
      Allowance.new(100)
      |> Allowance.write_buffer(data)
  end

  test "get the buffer and reset the continuation" do
    data = "hello"
    assert {^data, {{<<>>, nil}, 0}} =
      Allowance.new(byte_size(data))
      |> Allowance.write_buffer!(data)
      |> Allowance.get_and_reset_buffer
  end

  test "setting remaining" do
    assert {{<<>>, 5}, 0} =
      Allowance.new(nil)
      |> Allowance.set_remaining(5)
  end

  describe "integration tests" do
    test "integration test" do
      data = "foobarbaz"
      allowance = Allowance.new(byte_size(data), byte_size(data))

      # consume some ...
      {tokens, allowance} = Allowance.take_tokens(allowance, 6)
      {to_write, rest} = String.split_at(data, tokens)
      {:ok, allowance} = Allowance.write_buffer(allowance, to_write)
      # consume the rest
      {tokens, allowance} = Allowance.take_tokens(allowance, 3)
      {to_write, ""} = String.split_at(rest, tokens)

      assert {:ok, {{^data, 0}, 0}} = Allowance.write_buffer(allowance, to_write)
    end

    test "consuming length message and a message" do
      data = <<6, ?f, ?o, ?o, ?b, ?a, ?r>>
      max_tokens = 200

      # consume one byte (the length of the message)
      allowance = Allowance.new(1, 1)
      {tokens, allowance} = Allowance.take_tokens(allowance, max_tokens)

      # read the given tokens from the binary and convert the binary
      # value to an integer that we can use as a length for further
      # consummation
      <<consume::binary-size(tokens), rest::binary>> = data
      <<len::big-integer-size(8)>> = consume
      # write the data back to the buffer and get ready to consume the
      # rest of the message
      allowance =
        allowance
        |> Allowance.write_buffer!(consume)
        |> Allowance.set_remaining(len)
        |> Allowance.add_tokens(len)

      {tokens, allowance} = Allowance.take_tokens(allowance, max_tokens)

      <<consume::binary-size(tokens), _::binary>> = rest

      assert {^data, _} =
        allowance
        |> Allowance.write_buffer!(consume)
        |> Allowance.get_and_reset_buffer
    end
  end
end
