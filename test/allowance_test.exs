defmodule AllowanceTest do
  use ExUnit.Case
  doctest Allowance

  test "creating a allowance" do
    assert {200, <<>>, 0} = Allowance.new(200)
  end

  test "adding tokens" do
    assert {200, <<>>, 200} =
      Allowance.new(200)
      |> Allowance.add_tokens(200)
  end

  describe "taking tokens" do
    test "more than available tokens" do
      assert {100, {200, <<>>, 0}} =
        Allowance.new(200)
        |> Allowance.add_tokens(100)
        |> Allowance.take_tokens(200)
    end

    test "less than remaining" do
      assert {20, {200, <<>>, 180}} =
        Allowance.new(200)
        |> Allowance.add_tokens(200)
        |> Allowance.take_tokens(20)
    end

    test "more than remaining" do
      assert {20, {20, <<>>, 0}} =
        Allowance.new(20)
        |> Allowance.add_tokens(20)
        |> Allowance.take_tokens(100)
    end
  end

  test "writing data to a buffer" do
    data = "foobar"
    assert {:ok, {94, ^data, 0}} =
      Allowance.new(100)
      |> Allowance.write_buffer(data)
  end

  test "integration test" do
    data = "foobarbaz"
    allowance =
      byte_size(data)
      |> Allowance.new()
      |> Allowance.add_tokens(byte_size(data))

    # consume some ...
    {tokens, allowance} = Allowance.take_tokens(allowance, 6)
    {to_write, rest} = String.split_at(data, tokens)
    {:ok, allowance} = Allowance.write_buffer(allowance, to_write)
    # consume the rest
    {tokens, allowance} = Allowance.take_tokens(allowance, 3)
    {to_write, ""} = String.split_at(rest, tokens)

    assert {:ok, {0, ^data, 0}} = Allowance.write_buffer(allowance, to_write)
  end
end
