--- typelua-stdlib: small, typed, dependency-free standard-library helpers.

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

return {
  version = "v0.1.1",
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
}
