// Tests for the tooling itself: the list parser and every lint rule. No browser
// needed, only uBO Lite's parser (`just ubol`). Run with `just unit`.
import { describe, test } from "node:test";
import assert from "node:assert/strict";
import { readList, splitCosmetic } from "../scripts/list.mjs";
import { lint } from "../scripts/lint.mjs";

const fixture = (name) => new URL(`fixtures/${name}`, import.meta.url);

describe("readList", () => {
  test("reads notes, repeated test:/keep:, probe:, verified: and filters", async () => {
    const { blocks } = await readList(fixture("good.txt"));
    assert.equal(blocks.length, 2);
    const [a, b] = blocks;
    assert.deepEqual(a.notes, [
      "Two filters, two test pages, a probe and two keeps.",
      "Second line of notes.",
    ]);
    assert.deepEqual(a.tests, [
      "https://www.youtube.com/results?search_query=cats",
      "https://m.youtube.com/results?search_query=cats",
    ]);
    assert.equal(a.probe, "ytd-badge");
    assert.deepEqual(a.keep, ["ytd-video-renderer", "ytd-channel-renderer"]);
    assert.equal(a.verified, "2026-11-01");
    assert.deepEqual(
      a.filters.map((f) => [f.line, f.procedural, f.hosts]),
      [
        [14, true, ["youtube.com"]],
        [15, false, ["youtube.com", "~music.youtube.com"]],
      ],
    );
    assert.equal(b.line, 16, "a comment after filters starts a new block");
    assert.deepEqual(b.tests, ["https://news.example.com/"]);
    assert.deepEqual(b.keep, []);
    assert.equal(a.signedIn, false);
    assert.equal(b.signedIn, true);
  });

  test("splitCosmetic", () => {
    assert.deepEqual(splitCosmetic("a.com,~b.a.com##.x"), {
      hosts: ["a.com", "~b.a.com"],
      separator: "##",
      selector: ".x",
    });
    assert.equal(splitCosmetic("a.com#@?#.x").separator, "#@?#");
    assert.equal(splitCosmetic("||ads.com^"), null);
  });
});

describe("lint", () => {
  test("accepts a good list", async () => {
    const { problems, count } = await lint(fixture("good.txt"));
    assert.deepEqual(problems, []);
    assert.equal(count, 3);
  });

  test("reports every broken rule, on the right line", async () => {
    const file = fixture("bad.txt");
    const { problems } = await lint(file);
    const got = problems.map((p) => p.slice(String(file).length + 1));
    const expected = [
      [1, 'missing "! Expires:" header'],
      [5, 'block has no "! test:" URL'],
      [9, "uBO Lite rejects this filter"],
      [12, "generic filter"],
      [15, "only cosmetic hide filters"],
      [18, "only cosmetic hide filters"],
      [21, 'procedural filter needs a "! probe:"'],
      [23, "probe is not a plain CSS selector"],
      [27, "keep is not a plain CSS selector"],
      [32, "test URL host example.com is not covered by youtube.com"],
      [34, "bad test URL: not a url"],
      [38, "duplicate of line 6"],
    ];
    for (const [line, msg] of expected)
      assert.ok(
        got.some((p) => p.startsWith(`${line}: ${msg}`)),
        `expected "${line}: ${msg}…" in:\n${got.join("\n")}`,
      );
    assert.equal(got.length, expected.length, got.join("\n"));
  });
});
