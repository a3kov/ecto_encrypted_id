defmodule EctoEncryptedIdTest do
  use ExUnit.Case
  alias EctoEncryptedId.Encryption
  doctest EctoEncryptedId

  @key "NkhH77JcsCasa2HQHJZt10HbL1QLtj7S"

  def key(), do: @key

  defmodule TestField do
    use EctoEncryptedId, salt: "whatever", secret_key_fn: &EctoEncryptedIdTest.key/0
  end
  alias TestField.Id

  test "from_encrypted creates Id" do
    enc = Encryption.encrypt(123, @key, "whatever")
    assert Id.from_encrypted(enc) == {:ok, %Id{encrypted: enc, plain: 123}}
  end

  test "from_encrypted returns :error with invalid input" do
    assert Id.from_encrypted("wut") == :error
  end

  test "from_encrypted! creates Id" do
    enc = Encryption.encrypt(123, @key, "whatever")
    assert Id.from_encrypted!(enc) == %Id{encrypted: enc, plain: 123}
  end

  test "from_encrypted! raises with invalid input" do
    assert_raise EctoEncryptedId.DecryptionError, fn ->
      Id.from_encrypted!("wut")
    end
  end

  test "from_plain creates Id" do
    enc = Encryption.encrypt(123, @key, "whatever")
    assert Id.from_plain(123) == %Id{encrypted: enc, plain: 123}
  end
end
