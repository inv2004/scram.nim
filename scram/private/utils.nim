import random, base64, strutils, types, hmac, bitops
from md5 import MD5Digest
from sha1 import Sha1Digest
from nimSHA2 import Sha224Digest, Sha256Digest, Sha384Digest, Sha512Digest

randomize()

proc `$%`*[T](input: T): string =
  result = newString(input.len)
  for i in 0..<input.len:
    result[i] = input[i].char

template makeNonce*(): string =
  base64.encode(hmac_sha1($rand(int.high), "scram.nim"))

template `^=`*[T](a, b: T) =
  for x in 0..<a.len:
    when T is Sha1Digest or T is Keccak512Digest or T is SHA256Digest:
      a[x] = (a[x].int32 xor b[x].int32).uint8
    else:
      a[x] = (a[x].int32 xor b[x].int32).char

proc custom_xor*[T](bytes: T, str: string): string =
  if bytes.len != str.len:
    raise newException(RangeDefect, "xor must have both arguments of the same size")
  result = str
  for x in 0..<bytes.len:
    result[x] = (bytes[x].uint8 xor str[x].uint8).char

proc constantTimeEqual*(a, b: string): bool =
  if a.len != b.len:
    raise newException(RangeDefect, "must have both arguments of the same size")
  var res: uint8 = 0
  for x in 0..<a.len:
    res = bitor(res, bitxor(a[x].uint8, b[x].uint8))
  result = (res == 0)

proc HMAC*[T](password, salt: string): T =
  when T is MD5Digest:
    result = hmac_md5(password, salt)
  elif T is Sha1Digest:
    result = hmac_sha1(password, salt)
  elif T is Sha224Digest:
    result = hmac_sha224(password, salt)
  elif T is Sha256Digest:
    result = hmac_sha256(password, salt)
  elif T is Sha384Digest:
    result = hmac_sha384(password, salt)
  elif T is Sha512Digest:
    result = hmac_sha512(password, salt)
  elif T is Keccak512Digest:
    result = hmac_keccak512(password, salt)

proc raw_str*[T](digest: T): string =
  when T is Sha1Digest:
    for c in digest: result.add(char(c))
  else:
    result = $digest

proc HASH*[T](s: string): T =
  when T is MD5Digest:
    result = hash_md5(s)
  elif T is Sha1Digest:
    result = hash_sha1(s)
  elif T is Sha224Digest:
    result = hash_sha224(s)
  elif T is Sha256Digest:
    result = hash_sha256(s)
  elif T is Sha384Digest:
    result = hmac_sha384(s)
  elif T is Sha512Digest:
    result = hash_sha512(s)
  elif T is Keccak512Digest:
    result = hash_keccak512(s)

proc debug[T](s: T): string =
  result = ""
  for x in s:
    result.add strutils.toHex(x.uint8).toLowerAscii

proc hi*[T](password, salt: string, iterations: int): T =
  var previous = HMAC[T](password, salt & INT_1)
  result = previous
  for _ in 1..<iterations:
    previous = HMAC[T](password, $%previous)
    result ^= previous