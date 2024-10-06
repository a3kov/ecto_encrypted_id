defmodule EctoEncryptedIdTest do
  use ExUnit.Case
  alias EctoEncryptedId.Encryption
  doctest EctoEncryptedId

  @key <<78, 183, 35, 57, 53, 47, 79, 158, 4, 192, 130, 186, 141, 177, 99, 47, 158,
      144, 191, 151, 117, 90, 135, 197, 213, 88, 224, 32, 244, 111, 219, 223>>

  def key() do
    @key
  end

  defmodule TestField do
    use EctoEncryptedId, salt: "whatever", secret_key_fn: &EctoEncryptedIdTest.key/0
  end
  alias TestField.Id

  test "from_encrypted creates Id" do
    enc = Encryption.encrypt(123, @key, "whatever")
    assert Id.from_encrypted(enc, @key) == {:ok, %Id{encrypted: enc, plain: 123}}
  end

  test "from_encrypted returns :error with invalid input" do
    assert Id.from_encrypted("wut", @key) == :error
  end

  test "from_encrypted! creates Id" do
    enc = Encryption.encrypt(123, @key, "whatever")
    assert Id.from_encrypted!(enc, @key) == %Id{encrypted: enc, plain: 123}
  end

  test "from_encrypted! raises with invalid input" do
    assert_raise EctoEncryptedId.DecryptionError, fn -> Id.from_encrypted!("wut", @key) end
  end

  test "from_plain creates Id" do
    enc = Encryption.encrypt(123, @key, "whatever")
    assert Id.from_plain(123, @key) == %Id{encrypted: enc, plain: 123}
  end
end
