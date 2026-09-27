import { test } from "node:test";
import assert from "node:assert/strict";
import { ping } from "./ping.js";

test("ping devuelve pong", () => {
  assert.equal(ping(), "pong");
});
