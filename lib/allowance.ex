defmodule Allowance do
  @type remaining :: non_neg_integer
  @type tokens :: non_neg_integer
  @type buffer :: binary
  @type len :: non_neg_integer

  @type allowance :: {remaining, buffer, tokens}

  @spec new(len) :: allowance
  def new(initial_length), do: {initial_length, <<>>, 0}

  @spec add_tokens(allowance, tokens) :: allowance
  def add_tokens({remaining, buffer, current_tokens}, tokens),
    do: {remaining, buffer, current_tokens + tokens}

  @spec take_tokens(allowance, tokens) :: {allowance, tokens}
  def take_tokens({remaining, buffer, available_tokens}, tokens) when available_tokens < tokens do
    new_state = {remaining, buffer, 0}
    {available_tokens, new_state}
  end
  def take_tokens({remaining, buffer, available_tokens}, tokens) when tokens > remaining do
    new_state = {remaining, buffer, available_tokens - tokens}
    {remaining, new_state}
  end
  def take_tokens({remaining, buffer, available_tokens}, tokens) do
    new_state = {remaining, buffer, available_tokens - tokens}
    {tokens, new_state}
  end

  @spec set_length(allowance, len) :: allowance
  def set_length({0, buffer, tokens}, len), do: {len, buffer, tokens}

  @spec write_buffer(allowance, data :: binary) :: allowance
  def write_buffer({remaining, buffer, available_tokens}, data) when remaining - byte_size(data) >= 0 do
    new_state = {remaining - byte_size(data), buffer <> data, available_tokens}
    {:ok, new_state}
  end
  def write_buffer({_remaining, _buffer, _available_tokens}, _data),
    do: {:error, :out_of_bounds}
end
