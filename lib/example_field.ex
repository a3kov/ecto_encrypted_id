if Mix.env() != :prod do
  defmodule EctoEncryptedId.ExampleField do
    @moduledoc """
    Example module implementing encrypted field. Provides documentation for the
    injected functions and modules.
    """

    @doc false
    def secret_key() do
      "NkhH77JcsCasa2HQHJZt10HbL1QLtj7S"
    end

    use EctoEncryptedId, salt: "", secret_key_fn: &EctoEncryptedId.ExampleField.secret_key/0
  end
end
