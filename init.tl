--- typelua-stdlib: small, typed, dependency-free standard-library helpers.

import bitops from "./bitops"
import strings from "./strings"
import lists from "./lists"
import maps from "./maps"
import mathx from "./mathx"
import path from "./path"
import encoding from "./encoding"
import json from "./json"
import time from "./time"
import fs from "./fs"
import random from "./random"
import hash from "./hash"
import csv from "./csv"
import set from "./set"
import semver from "./semver"
import url from "./url"
import binary from "./binary"
import unicode from "./unicode"
import entropy from "./entropy"
import netip from "./netip"
import crc32 from "./crc32"
import collections from "./collections"

return {
  version = "v0.2.5",
  bitops = bitops,
  strings = strings,
  lists = lists,
  maps = maps,
  mathx = mathx,
  path = path,
  encoding = encoding,
  json = json,
  time = time,
  fs = fs,
  random = random,
  hash = hash,
  csv = csv,
  set = set,
  semver = semver,
  url = url,
  binary = binary,
  unicode = unicode,
  entropy = entropy,
  netip = netip,
  crc32 = crc32,
  collections = collections,
}
