if Mix.env() != :prod do
  defmodule EctoEncryptedId.ExampleField do
    @moduledoc """
    Example module implementing encrypted field. Provides documentation for the
    injected functions and modules.
    """

    @doc false
    def secret_key() do
      "U21b5SCcJbAdhsNKweLLqBwexU3mvOXJPHNG5tjxJstWraDeI0nceFLQdkHK4WNF"
    end

    use EctoEncryptedId, salt: "", secret_key_fn: &EctoEncryptedId.ExampleField.secret_key/0
  end
end
