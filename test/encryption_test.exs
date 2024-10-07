defmodule EncryptionTest do
  use ExUnit.Case, async: true
  use ExUnitProperties
  alias EctoEncryptedId.Encryption

  @min_pg_int -9_223_372_036_854_775_808
  @max_pg_int 9_223_372_036_854_775_807

  property "encrypt |> decrypt produces original value" do
    check all(
            key <- binary(length: 32),
            salt <- binary(max_length: 32),
            num <- integer(@min_pg_int..@max_pg_int),
            max_runs: 10_000
          ) do
      encrypted = Encryption.encrypt(num, key, salt)
      assert Encryption.decrypt(encrypted, key) == {:ok, num}
    end
  end

  property "encryption is deterministic" do
    check all(
            key <- binary(length: 32),
            salt <- binary(max_length: 32),
            num <- integer(@min_pg_int..@max_pg_int),
            max_runs: 10
          ) do
      encrypted1 = Encryption.encrypt(num, key, salt)
      encrypted2 = Encryption.encrypt(num, key, salt)
      assert encrypted1 == encrypted2
    end
  end
end
