defmodule Allowance do
  @type tokens :: non_neg_integer
  @type buffer :: binary
  @type remaining :: non_neg_integer | nil

  @type continuation :: {buffer, remaining}
  @type allowance :: {continuation, tokens}

  @spec new(remaining, tokens) :: allowance
  def new(expected_message_length, tokens \\ 0),
    do: {{<<>>, expected_message_length}, tokens}

  @spec add_tokens(allowance, tokens) :: allowance
  def add_tokens({continuation, current_tokens}, tokens),
    do: {continuation, current_tokens + tokens}

  @spec set_tokens(allowance, tokens) :: allowance
  def set_tokens({continuation, _}, tokens),
    do: {continuation, tokens}

  @spec take_tokens(allowance, tokens) :: {allowance, tokens}
  def take_tokens({continuation, available_tokens}, tokens) when available_tokens < tokens do
    new_state = {continuation, 0}
    {available_tokens, new_state}
  end
  def take_tokens({{_, remaining} = continuation, available_tokens}, tokens) when tokens > remaining do
    new_state = {continuation, available_tokens - tokens}
    {remaining, new_state}
  end
  def take_tokens({continuation, available_tokens}, tokens) do
    new_state = {continuation, available_tokens - tokens}
    {tokens, new_state}
  end

  @spec set_remaining(allowance, remaining) :: allowance
  def set_remaining({{buffer, _}, tokens}, remaining),
    do: {{buffer, remaining}, tokens}

  @spec get_and_reset_buffer(allowance) :: {buffer, allowance}
  def get_and_reset_buffer({{buffer, 0}, tokens}),
    do: {buffer, Allowance.new(nil, tokens)}

  @spec write_buffer(allowance, data :: binary) ::
    {:ok, allowance} |
    {:error, :out_of_bounds}
  def write_buffer({{buffer, remaining}, available_tokens}, data) when remaining - byte_size(data) >= 0 do
    new_state = {{buffer <> data, remaining - byte_size(data)}, available_tokens}
    {:ok, new_state}
  end
  def write_buffer({_continuation, _available_tokens}, _data),
    do: {:error, :out_of_bounds}

  @spec write_buffer!(allowance, data :: binary) :: allowance | no_return
  def write_buffer!(allowance, data) do
    {:ok, result} = write_buffer(allowance, data)
    result
  end
end
