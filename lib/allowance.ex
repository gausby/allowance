defmodule Allowance do
  @type remaining :: non_neg_integer
  @type tokens :: non_neg_integer
  @type buffer :: binary
  @type len :: non_neg_integer

  @type continuation :: {buffer, remaining}
  @type allowance :: {continuation, tokens}

  @spec new(initial_length :: len) :: allowance
  def new(initial_length), do: {{<<>>, initial_length}, 0}

  @spec add_tokens(allowance, tokens) :: allowance
  def add_tokens({continuation, current_tokens}, tokens),
    do: {continuation, current_tokens + tokens}

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

  @spec set_length(allowance, len) :: allowance
  def set_length({{buffer, _}, tokens}, len), do: {{buffer, len}, tokens}

  @spec write_buffer(allowance, data :: binary) :: allowance
  def write_buffer({{buffer, remaining}, available_tokens}, data) when remaining - byte_size(data) >= 0 do
    new_state = {{buffer <> data, remaining - byte_size(data)}, available_tokens}
    {:ok, new_state}
  end
  def write_buffer({_continuation, _available_tokens}, _data),
    do: {:error, :out_of_bounds}
end
